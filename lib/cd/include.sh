#!/usr/bin/env bash

APPLICABLE_SERVICES+=("cd")

function setup_cd() {
    apt-get -y update --fix-missing
    apt-get -y install openssh-server curl software-properties-common apt-transport-https netcat git curl
}

function ensure_pssh_installed() {
    if [ -z $(command -v parallel-ssh) ]; then
        warn "$ssh_host: installing pssh on the controller"
        apt-get -y update
        continue $? "$ssh_host: could not update package repos"
        apt-get -y install pssh
        continue $? "$ssh_host: could not install parallel-ssh"
    fi
    if [ -z $(command -v pssh) ]; then
        pssh=`which parallel-ssh`
        ln -s $pssh "$(dirname $pssh)/pssh"
        continue $? "$ssh_host: could not create pssh alias"
    fi
}