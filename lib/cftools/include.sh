#!/usr/bin/env bash

checkvar CF_VERSION

APPLICABLE_SERVICES+=("cftools")

CF="${CF_VERSION:0:3}"

setup_cftools() {
    curl -s https://packages.confluent.io/deb/$CF/archive.key | apt-key add -
    continue $? "could not add confluent repo key"
    add-apt-repository -y "deb [arch=amd64] https://packages.confluent.io/deb/$CF stable main"
    continue $? "could not add confluent repository"
    apt-get update
    continue $? "could not add confluent repository"
}
