#!/usr/bin/env bash

checkvar CF_VERSION

required "cftools"

APPLICABLE_SERVICES+=("librdkafka")

CF="${CF_VERSION:0:3}"

setup_librdkafka() {
    yum install -y gcc
    yum install -y librdkafka-devel
    apt-get install -y librdkafka-dev
}
