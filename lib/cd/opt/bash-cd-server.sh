#!/usr/bin/env bash

CD_PORT=7480

#THIS IS A SIMPLE BASH SERVER FOR GITHUB WEBHOOK
#IT SHOULD BE INSTALLED AS A SYSTEM SERVICE BY env/setup.sh

source /opt/bash-cd/lib/tools.sh

exec >> /var/log/bash-cd.log
exec 2>&1

handle() {
    cd /opt/bash-cd
    read in
    if [[ "$in" == "POST /push"* ]]; then
        branch=$(git rev-parse --abbrev-ref HEAD)
        local_revision=$(git rev-parse $branch)
        git remote update &> /dev/null
        remote_revision=$(git rev-parse origin/$branch)
        rollback_file="$DIR/unclean"
        declare changed=0
        if [ -f "$rollback_file" ]; then
            warn "RESUMING INCOMPLETE BUILD: $(cat $rollback_file)"
            changed=1
        elif [ $local_revision != $remote_revision ]; then
            highlight "ENVIRONMENT CHANGE DETECTED ($in), LOCAL: $local_revision, REMOTE: $remote_revision"
            changed=1
            echo $(git rev-parse HEAD) > $rollback_file
        fi
        if [ $changed -eq 1 ]; then
            git pull
            continue $? "COULD NOT PULL THE LATEST ENVIRONMENT CHANGES"
            ./apply.sh setup
            ./apply.sh install
            rm $rollback_file
        fi
    elif [[ "$in" == "POST /install"* ]]; then
        ./apply.sh install
    else
        fail "$in"
    fi
}

highlight "BASH-CD SERVER LISTENING ON PORT: $CD_PORT"
echo "POST /push" | handle # trigger initial build that may need resuming after reboot
RESPONSE="HTTP/1.1 200 OK\r\nConnection: keep-alive\r\n\r\n${2:-"OK"}\r\n"
while { echo -en "$RESPONSE"; } | nc -l "${1:-$CD_PORT}" | handle; do sleep 3; done

## use the following code instead of the 4-lines above if you don't have a way of receiving webhook HTTP POST requests
#highlight "BASH-CD SERVER WATCHING REMOTE GIT REPO"
#while [ 1 ]; do
#    echo "POST /push BASH/LOOP" | handle
#    sleep 15
#done