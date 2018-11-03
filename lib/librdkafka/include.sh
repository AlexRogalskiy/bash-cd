#!/usr/bin/env bash

required "cftools"

APPLICABLE_SERVICES+=("librdkafka")

setup_librdkafka() {
    apt-get install -y librdkafka-dev
}
