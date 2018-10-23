#!/usr/bin/env bash

checkvar CF_VERSION

APPLICABLE_SERVICES+=("librdkafka")

required "cftools"

CF="${CF_VERSION:0:3}"

setup_librdkafka() {
    apt-get install -y librdkafka-dev
}
