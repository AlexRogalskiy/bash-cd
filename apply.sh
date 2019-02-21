#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/lib/tools.sh
source $DIR/lib/fix.sh
source $DIR/env/var.sh

function usage() {
    fail "Usage: apply.sh  <user>@<ssh-host>[:<ssh-port>] [--module <lib-module-name>]"
}

if [ -z "$1" ]; then
    usage
    exit 1
fi

controller=0
if [ "$1" == "--controller" ]; then
    controller=1
    shift
fi

ssh_port=22
case $1 in
  (*:*) ssh_host=${1%:*} ssh_port=${1##*:};;
  (*)   ssh_host=$1      ssh_port=22;;
esac
if (( controller == 0 )); then
    #TODO check if ssh-add needs to be executed
    #eval `ssh-agent -s`
    #ssh-add
    #rsync to the controller and continue from there
    info "Control SSH Host: $ssh_host"
    info "Control SSH Port: $ssh_port"
    rsync -lvzruq -e "ssh -p $ssh_port" --exclude 'Vagrantfile' --exclude 'build' --exclude '.*' --delete $DIR $ssh_host:~
    continue $? "could not rsync the controller host: $ssh_host"
    ssh -T -A -p $ssh_port $ssh_host "~/bash-cd/apply.sh --controller $@"
    exit $?
fi
shift;

while [ ! -z "$1" ]; do
    cmd="$1"; shift
    case $cmd in
        help*) usage;;
        --module*) MODULES=($1); shift;;
        *) usage;;
    esac
done

for host in "${HOSTS[@]}"
do
    if [ ! -z "$host" ]; then
        info "$ssh_host: rsync $DIR -> ${HOSTS[@]}:~/bash-cd"
        rsync -lvzruq -e 'ssh -o StrictHostKeyChecking=no' --exclude 'build'--delete $DIR $host:~
        continue $? "$ssh_host: could not rsync from the controller into $host"
    fi
done

if [ -z $(command -v pssh) ]; then
    warn "installing pssh on the controller"
    apt-get -y update
    continue $?
    apt-get -y install pssh
    continue $?
fi

checkvar MODULES
PRIMARY_IP=""
for module in "${MODULES[@]}"
do
    required $module
done

REQUIRED_MODULES=("${_LOADED_MODULES_BASH_CD[@]}")
for module in "${REQUIRED_MODULES[@]}"
do
    parallel=1
    #TODO if module defines rolling install parallel=0
    if (( parallel == 1 )); then
        info "$module => ${HOSTS[@]}"
    else
        for host in "${HOSTS[@]}"
        do
            warn "$module -> $host"
        done
    fi
done


