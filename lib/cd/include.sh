#!/usr/bin/env bash

APPLICABLE_SERVICES+=("cd")

setup_cd() {
    apt-get -y update --fix-missing
    apt-get -y install curl software-properties-common apt-transport-https netcat git
}

install_cd() {
    systemctl daemon-reload
    systemctl enable cd.service
}

#cd service restart instead of stop-start because the running /opt/bash-cd-server.sh gets interrupted
start_cd() {
    systemctl restart cd.service || systemctl start cd.service
}