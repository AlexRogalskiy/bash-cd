#!/usr/bin/env bash

export KAFKA_METRICS_HOME="/opt/kafka-metrics"

APPLICABLE_SERVICES+=("kafka-metrics")

function install_kafka-metrics() {
    git_clone_or_update https://github.com/amient/kafka-metrics.git "$KAFKA_METRICS_HOME" "master"
    cd $KAFKA_METRICS_HOME
    ./gradlew --no-daemon -q :influxdb-loader:build
}
