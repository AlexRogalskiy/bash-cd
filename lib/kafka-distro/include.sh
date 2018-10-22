#!/usr/bin/env bash

checkvar KAFKA_VERSION

required "openjdk8"

KAFKA_PACKAGE="kafka_2.11-$KAFKA_VERSION"
APPLICABLE_SERVICES+=("kafka-distro")

build_kafka-distro() {
    download "http://www.mirrorservice.org/sites/ftp.apache.org/kafka/$KAFKA_VERSION/$KAFKA_PACKAGE.tgz" "/opt/kafka"
    if [ ! -d "/opt/kafka/$KAFKA_PACKAGE" ]; then
        tar -xzf "/opt/kafka/$KAFKA_PACKAGE.tgz" -C "/opt/kafka"
    fi
}

install_kafka-distro() {
    ln -fsn "/opt/kafka/$KAFKA_PACKAGE" "/opt/kafka/current"
}
