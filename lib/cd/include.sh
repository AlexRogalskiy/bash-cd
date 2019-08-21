#!/usr/bin/env bash

apply "cd"

function setup_cd() {
    apt-get -y update
    apt-get -y install software-properties-common apt-transport-https netcat curl git
    continue $?
}