#!/usr/bin/env bash

apply "cftools"
apply "librdkafka"

setup_librdkafka() {
    apt-get install -y librdkafka-dev
}
