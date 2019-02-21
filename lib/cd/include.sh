#!/usr/bin/env bash

setup_cd() {
    apt-get -y update --fix-missing
    apt-get -y install openssh-server pssh curl software-properties-common apt-transport-https netcat git
}

