#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/lib/tools.sh

function usage() {
    fail "Usage: apply.sh  <user>@<control-host>[:<ssh-port>] [--module <lib-module-name>]"
}

if [ -z "$1" ]; then
    usage
    exit 1
fi

ssh_port=22
case $1 in
  (*:*) ssh_host=${1%:*} ssh_port=${1##*:};;
  (*)   ssh_host=$1      ssh_port=22;;
esac

echo "Control SSH Host: $ssh_host"
echo "Control SSH Port: $ssh_port"

eval `ssh-agent -s`

ssh -A $ssh_host -p $ssh_port


#TODO rsync everything
#TODO ssh -A -T into the control-host and execute ./apply

