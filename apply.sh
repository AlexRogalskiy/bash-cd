#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/lib/tools.sh
source $DIR/env/var.sh

function usage() {
    fail "Usage: ./apply.sh [--controller] --ssh <USER>@<HOST>[:<PORT>] [--template <YAML-TEMPLATE-FILE>] [--org <>] [--adminpwd <>] [--fqn <>] [--module <MODULE>]"
}

ARGS=( "$@" )

MODULE="-"
HOST=""
sync_only=0
quick=0
controller=0
while [ ! -z "$1" ]; do
    cmd="$1"
    case $cmd in
        --controller*) shift; controller=1;;
        --ssh*) shift; SSH=$1 shift;;
        --org*) shift; org_id=$1; shift;;
        --adminpwd*) shift; adminpwd=$1; shift;;
        --fqn*) shift; publicfqn=$1; shift;;
        --branch*) shift; branch=$1; shift;;
        --module*) shift; MODULE=$1; quick=1; shift;;
        --sync-only*) shift; sync_only=1; shift;;
        --host*) shift; HOST=$1; shift;;
        *)
            fail "unsupported option $cmd"
        break;;
    esac
done
case $SSH in
  (*:*) SSH_HOST=${SSH%:*} SSH_PORT=${SSH##*:};;
  (*)   SSH_HOST=$SSH      SSH_PORT=22;;
esac

SSH_USER=${SSH_HOST%@*}
SUDO="sudo"
if [ "$USER" == "root" ]; then SUDO=""; fi

if (( controller == 0 )); then
    #starting on a local machine

    info "Control SSH Host: $SSH_HOST"
    info "Control SSH Port: $SSH_PORT"

    eval `ssh-agent -s`
    continue $? "could not start ssh-agent"
    if [ ! -z "$SSH_KEY" ]; then
      ssh-add $SSH_KEY
      continue $?
    fi

    branch=$(git rev-parse --abbrev-ref HEAD)
    continue $? "could not get current branch"

    if (( quick == 0 )); then
    ssh -A -T -o "StrictHostKeyChecking no" $SSH_HOST -p $SSH_PORT $SUDO /bin/bash  -v << EOF
if [ -z \$(command -v rsync) ];then
    DEBIAN_FRONTEND=noninteractive
    apt-get -y update
    apt-get -y install rsync
fi
EOF
    fi
    continue $? "could not ensure rsync on the controller"

    #rsync all code to the controller before the handover
    rsync -lvzruq -e "ssh -p $SSH_PORT -o StrictHostKeyChecking=no" \
        --exclude 'Vagrantfile' \
        --exclude 'build' \
        --exclude '.*' \
        --delete $DIR/ $SSH_HOST:~/bash-cd
    continue $? "could not rsync the controller host: $SSH_HOST"

    highlight "Controller synced successfully, handing over.."
    if (( sync_only == 0 )); then
        ssh -T -A -p $SSH_PORT $SSH_HOST "~/bash-cd/apply.sh --controller --branch $branch ${ARGS[@]}"
    fi
    exit $?
fi


##### FROM HERE THIS GETS EXECUTED ON THE CONTROLLER HOST #############################################################

info "INITIALIZING THE CONTROLLER; BRANCH=$branch; ORG_ID=$org_id; FQN=$publicfqn"


if (( quick == 0 )); then

#    log "ensure controller is addressable by private ip locally"
#    h=$(hostname)
#    ip=($(hostname --all-ip-addresses))
#    c=$(cat /etc/hosts | grep $h)
#    if [ -z "$c" ]; then
#        echo "${ip[0]} $h" >> /etc/hosts
#    fi

    log "ensure pssh on controller"
    if [ -z $(command -v parallel-ssh) ]; then
        warn "$SSH_HOST: installing pssh on the controller"
        $SUDO apt-get -y update
        continue $? "$SSH_HOST: could not update package repos"
        $SUDO apt-get -y install pssh
        continue $? "$SSH_HOST: could not install parallel-ssh"
    fi
    if [ -z $(command -v pssh) ]; then
        pssh=`which parallel-ssh`
        $SUDO ln -s $pssh "$(dirname $pssh)/pssh"
        continue $? "$SSH_HOST: could not create pssh alias"
    fi
    if [ -z $(command -v pscp) ]; then
        pscp=`which parallel-scp`
        $SUDO ln -s $pscp "$(dirname $pscp)/pscp"
        continue $? "$SSH_HOST: could not create pscp alias"
    fi
fi

checkvar HOSTS

H=""
for host in "${HOSTS[@]}"; do if [ ! -z "$host" ]; then H="$H -H $host"; fi; done
if [ ! -z "$HOST" ]; then
    log "executing on a single host: $HOST"
    APPLY_HOSTS=($HOST);
else
    log "executing on all hosts"
    APPLY_HOSTS=(${HOSTS[@]});
fi
AH=""
for host in "${APPLY_HOSTS[@]}"; do if [ ! -z "$host" ]; then AH="$AH -H $host"; fi; done

if (( quick == 0 )); then
    info "PARALLEL: ENSURE ALL HOSTS HAVE KEYS GENERATED: $H"
    pssh -t 60 $H -x "-T" -x "-o StrictHostKeyChecking=no" --inline "/bin/bash  -c 'if [ ! -f ~/.ssh/id_rsa.pub ];then rm  ~/.ssh/id_rsa*; ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa; fi'"
    continue $? "failed to ensure access keys on all hosts"

    info "PARALLEL: ENSURE RSYNC ON ALL HOSTS: $AH "
    pssh -t 180 $AH -x "-T" -x "-o StrictHostKeyChecking=no" --print "$SUDO /bin/bash -c 'if [ -z \$(command -v rsync) ]; then DEBIAN_FRONTEND=noninteractive; apt-get -y update; apt-get -y install rsync; fi;'"
    continue $? "$host $SUDO /bin/bash -v update && install rsync"

    info "SERIAL: GATHER AUTHORIZATION KEYS"
    AUTHORIZED_KEYS="/tmp/authorization_keys2"
    echo "" > $AUTHORIZED_KEYS
    for host in "${HOSTS[@]}"
    do
        if [ ! -z "$host" ]; then
            AUTHORIZED_KEY="$(ssh -T -o "StrictHostKeyChecking no" $host $SUDO cat ~/.ssh/id_rsa.pub)"
            continue $?
            echo "$AUTHORIZED_KEY" >> $AUTHORIZED_KEYS
        fi
    done

    info "PARALLEL: INITIALIZING SSH KEYS ON HOSTS AS ${USER}"
    pscp $AH -x "-T" -x "-o StrictHostKeyChecking=no" $AUTHORIZED_KEYS ~/.ssh/authorized_keys2
    continue $?
fi

info "SERIAL: RSYNC HOSTS"
for host in "${APPLY_HOSTS[@]}"
do
    if [ ! -z "$host" ]; then
        if [ "$host" != "$PRIMARY_IP" ]; then
            info "rsync host $host: $DIR"
            rsync -lvzruq -e 'ssh -o StrictHostKeyChecking=no' --exclude 'build' --delete $DIR $host:~
            continue $? "CONTROLLER: could not rsync from the controller into $host"
        fi
    fi
done

function applyModule() {
    module="$1"
    parallel=1
    if [ "$(type -t rolling_$module)" == "function" ]; then parallel=0; fi
    if (( parallel == 1 )); then
        info "---------------------------------------------------------------------------------------------------------"
        info "PARALLEL: $module => $AH"
        info "---------------------------------------------------------------------------------------------------------"
        pssh -t 100000000 $AH -x "-T" -x "-o StrictHostKeyChecking=no" --inline "$SUDO ~/bash-cd/lib/apply.sh --module $module --skip-dependencies"
        continue $? "FAILURE: PARALLEL: $module => ${APPLY_HOSTS[@]}"
    else
        for host in "${APPLY_HOSTS[@]}"
        do
            info "---------------------------------------------------------------------------------------------------------"
            info "SERIAL: $module -> $host"
            info "---------------------------------------------------------------------------------------------------------"
            ssh -T -o StrictHostKeyChecking=no $host "$SUDO ~/bash-cd/lib/apply.sh --module $module --skip-dependencies"
            continue $? "FAILURE: SERIAL: $module -> $host"
        done
    fi
}

if (( quick == 1 )); then
    applyModule $MODULE
else
    info "========================================================================================================="
    info "PARALLEL: ALL MODULES => $AH"
    info "========================================================================================================="
    pssh -t 100000000 $AH -x "-T" -x "-o StrictHostKeyChecking=no" --print "$SUDO ~/bash-cd/lib/apply.sh"
    continue $? "FAILURE: PARALLEL: ALL MODULES => ${APPLY_HOSTS[@]}"

fi
