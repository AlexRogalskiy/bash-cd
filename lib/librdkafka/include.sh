#!/usr/bin/env bash

checkvar CF_VERSION

APPLICABLE_SERVICES+=("librdkafka")

CF="${CF_VERSION:0:3}"

setup_librdkafka() {
    curl -s https://packages.confluent.io/deb/$CF/archive.key | apt-key add -
    continue $? "could not add confluent repo key"
    add-apt-repository -y "deb [arch=amd64] https://packages.confluent.io/deb/$CF stable main"
    apt-get install -y librdkafka-dev
}
