#!/usr/bin/env bash

checkvar CF_VERSION

APPLICABLE_SERVICES+=("librdkafka")

CF="${CF_VERSION:0:3}"

setup_librdkafka() {
    rpm --import https://packages.confluent.io/rpm/$CF/archive.key
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
    yum install -y gcc
    yum install -y librdkafka-devel
}
