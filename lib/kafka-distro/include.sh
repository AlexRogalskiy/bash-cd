#!/usr/bin/env bash

required "openjdk8"

KAFKA_VERSION="2.0.0"
KAFKA_PACKAGE="kafka_2.11-$KAFKA_VERSION"
APPLICABLE_SERVICES+=("kafka-distro")

build_kafka-distro() {
    checkvar BUILD_DIR
    kafka_home="$BUILD_DIR/opt/kafka/$KAFKA_PACKAGE"
    download "http://www.mirrorservice.org/sites/ftp.apache.org/kafka/$KAFKA_VERSION/$KAFKA_PACKAGE.tgz" "$BUILD_DIR/opt/kafka"
    if [ ! -d "$kafka_home" ]; then
        tar -xzf "$BUILD_DIR/opt/kafka/$KAFKA_PACKAGE.tgz" -C "$BUILD_DIR/opt/kafka"
    fi
}

install_kafka-distro() {
    ln -fsn "/opt/kafka/$KAFKA_PACKAGE" "/opt/kafka/current"
}
