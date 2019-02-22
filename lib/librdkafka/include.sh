#!/usr/bin/env bash

required "cftools"

APPLICABLE_MODULES+=("librdkafka")

setup_librdkafka() {
    apt-get install -y librdkafka-dev
}
