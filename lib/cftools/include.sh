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
    rpm --import https://packages.confluent.io/rpm/$CF_MINOR_VERSION/archive.key
    continue $? "could not add confluent repo key"
    cat >  /etc/yum.repos.d/confluent.repo <<EOL
[Confluent.dist]
name=Confluent repository (dist)
baseurl=https://packages.confluent.io/rpm/$CF_MINOR_VERSION/7
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/$CF_MINOR_VERSION/archive.key
enabled=1

[Confluent]
name=Confluent repository
baseurl=https://packages.confluent.io/rpm/$CF_MINOR_VERSION
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/$CF_MINOR_VERSION/archive.key
enabled=1
EOL
    continue $? "could not add confluent repository"
}
