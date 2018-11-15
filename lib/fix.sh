#!/usr/bin/env bash

KAFKA_VERSION=2.0.0

SERVICES=(
    "cd"
    "zookeeper"
    "kafka"
    "kafka-topics"
    "schema-registry"
    "grafana"
    "prometheus"
)

GIT_SERVER_DATA_DIR=/data/git

ZOOKEEPER_PORT=2181

SCHEMA_REGISTRY_PORT=8081

KAFKA_LOG_DIRS="/data/kafka"
KAFKA_PORT=9092

GRAFANA_PORT=3000

PROMETHEUS_DATA_DIR=/data/prometheus/
