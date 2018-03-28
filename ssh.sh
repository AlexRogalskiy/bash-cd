#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/env/var.sh

HOST="$1"

if [ -z "$HOST" ]; then
    echo "Usage: ssh.sh <host>"
    exit 1;
fi

HOST_SSH_VAR="${HOST}_WAN"
HOST_SSH="ubuntu@${!HOST_SSH_VAR}"
ssh -i $SSH_KEY $HOST_SSH