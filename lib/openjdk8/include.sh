#!/usr/bin/env bash

apply "openjdk8"

setup_openjdk8() {
    update-ca-certificates -f
    apt-get -y install openjdk-8-jdk
}
