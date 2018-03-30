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
    echo "$in"
    if [[ "$in" == "POST /push"* ]]; then
        git remote update
        rollback_file="$DIR/unclean"
        declare changed=0
        if [ -f "$rollback_file" ]; then
            warn "RESUMING INCOMPLETE BUILD: $(cat $rollback_file)"
            changed=1
        elif [[ "$(git status | grep 'Your branch is behind')" == "Your branch is behind"* ]]; then
            highlight "ENVIRONMENT CHANGE DETECTED (POST /PUSH)"
            changed=1
            echo $(git rev-parse HEAD) > $rollback_file
        fi
        if [ $changed -eq 1 ]; then
            setup_checksum_before=$(checksum "env/setup.sh")
            git pull
            continue $? "COULD NOT PULL THE LATEST ENVIRONMENT CHANGES"
            setup_checksum_after=$(checksum "env/setup.sh")
            if [ "$setup_checksum_before" != "$setup_checksum_after" ]; then
                warn "SYSTEM UPDATE DETECTED"
                ./env/setup.sh
                git checkout $rollback_hash
                continue $? "SYSTEM UPDATE FAILED"
                ./apply.sh install --rebuild
            else
                ./apply.sh install
            fi
            continue $? "ENVIRONMENT INSTALL FAILED"
            rm $rollback_file
        else
            echo "No changes to apply."
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
