#!/usr/bin/env bash

required "openjdk8"

kafka_version="1.0.1"
kafka_package="kafka_2.11-$kafka_version"
APPLICABLE_SERVICES+=("kafka-distro")

build_kafka-distro() {
    checkvar BUILD_DIR
    kafka_home="$BUILD_DIR/opt/kafka/$kafka_package"
    download "http://www.mirrorservice.org/sites/ftp.apache.org/kafka/$kafka_version/$kafka_package.tgz" "$BUILD_DIR/opt/kafka"
    if [ ! -d "$kafka_home" ]; then
        tar -xzf "$BUILD_DIR/opt/kafka/$kafka_package.tgz" -C "$BUILD_DIR/opt/kafka"
    fi
}

install_kafka-distro() {
    ln -fs "/opt/kafka/$kafka_package" "/opt/kafka/current"
}
