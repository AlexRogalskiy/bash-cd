#!/usr/bin/env bash

checkvar GIT_SERVER
checkvar GIT_SERVER_DATA_DIR

if [ "$GIT_SERVER" == "$PRIMARY_IP" ]; then
    export GIT_SERVER_DATA_DIR
    APPLICABLE_SERVICES+=("gitd")
fi

setup_gitd() {
    apt-get -y update --fix-missing
    apt-get -y install git
}

install_gitd() {
    id -u git > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        adduser --no-create-home --shell /bin/false git
    fi
    mkdir -p "$GIT_SERVER_DATA_DIR"
    chown -R git:git $GIT_SERVER_DATA_DIR
    create_gitd_repo project
}

start_gitd() {
    systemctl start git-daemon
}

function stop_gitd() {
    systemctl stop git-daemon
}

function create_gitd_repo() {
    name="$1"
    dir="$GIT_SERVER_DATA_DIR/$name.git"
    if [ -d $dir ]; then
        mkdir -p $dir
        chown -R git:git $dir
        cd $dir
        git init --bare --shared
    fi
}