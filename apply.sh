#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/lib/tools.sh

function usage() {
    fail "Usage: apply.sh  <user>@<control-host> [--module <lib-module-name>]"
}

if [ -z "$1" ]; then
    usage
    exit 1
fi

eval `ssh-agent -s`


#TODO rsync everything
#TODO ssh -A -T into the control-host and execute ./apply

