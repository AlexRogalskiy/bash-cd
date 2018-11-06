#!/usr/bin/env bash

checkvar KAFKA_VERSION
checkvar KAFKA_MINOR_VERSION

export CF_VERSION
case $KAFKA_MINOR_VERSION in
    2.0*)
        CF_VERSION="5.0.0"
    ;;
    1.1*)
        CF_VERSION="4.1.1"
    ;;
    1.0*)
        CF_VERSION="4.0.0"
    ;;
    0.11*)
        CF_VERSION="3.3.1"
    ;;
    *)
        fail "unsupported kafka minor version $KAFKA_MINOR_VERSION"
    ;;
esac


APPLICABLE_SERVICES+=("cftools")

CF_MINOR_VERSION=$(cut -d '.' -f 1,2 <<< $CF_VERSION)

setup_cftools() {
    curl -s https://packages.confluent.io/deb/$CF_MINOR_VERSION/archive.key | apt-key add -
    continue $? "could not add confluent repo key"
    add-apt-repository -y "deb [arch=amd64] https://packages.confluent.io/deb/$CF_MINOR_VERSION stable main"
    continue $? "could not add confluent repository"
    apt-get update
    continue $? "could not add confluent repository"
}
