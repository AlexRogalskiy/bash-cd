#!/usr/bin/env bash

checkvar CF_VERSION

CF="${CF_VERSION:0:3}"

setup_cftools() {
    rpm --import https://packages.confluent.io/rpm/$CF/archive.key
    continue $? "could not add confluent repo key"
    cat >  /etc/yum.repos.d/confluent.repo <<EOL
[Confluent.dist]
name=Confluent repository (dist)
baseurl=https://packages.confluent.io/rpm/$CF/7
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/$CF/archive.key
enabled=1

[Confluent]
name=Confluent repository
baseurl=https://packages.confluent.io/rpm/$CF
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/$CF/archive.key
enabled=1
EOL
}
