#!/usr/bin/env bash

required "cftools"

APPLICABLE_SERVICES+=("librdkafka")

setup_librdkafka() {
    yum install -y gcc
    yum install -y librdkafka-devel
    apt-get install -y librdkafka-dev
}
