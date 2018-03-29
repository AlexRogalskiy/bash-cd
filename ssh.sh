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
HOST_SSH_KEY_VAR="${HOST}_SSH_KEY"
HOST_SSH_KEY="${!HOST_SSH_KEY_VAR}"

if [ -z "$HOST_SSH_KEY" ]; then HOST_SSH_KEY=$SSH_KEY; fi
ssh -i $HOST_SSH_KEY $HOST_SSH
