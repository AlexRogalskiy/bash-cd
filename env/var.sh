#!/usr/bin/env bash

KAFKA_VERSION=2.0.0
CF_VERSION=5.0.0

SERVICES=(
    "cd"
    "zookeeper"
    "kafka"
    "kafka-cli"
    "kafka-topics"
    "schema-registry"
    #
    "grafana"
    "prometheus"
)

ZK_SERVERS=($HOST1)
export ZOOKEEPER_PORT="2181"
export SCHEMA_REGISTRY_HOST=$HOST1
export SCHEMA_REGISTRY_PORT="8082"
export AVRO_COMPATIBILITY_LEVEL=full_transitive

KAFKA_SERVERS=($HOST1)
export KAFKA_LOG_DIRS="/data/kafka"
export KAFKA_PROTOCOL="PLAINTEXT"
export KAFKA_REPL_FACTOR=1
export KAFKA_PORT="9092"
#export KAFKA_SASL_MECHANISM=PLAIN
#export KAFKA_AUTHORIZER_CLASS_NAME=kafka.security.auth.SimpleAclAuthorizer

GRAFANA_SERVERS=($HOST1)
PROMETHEUS_SERVERS=($HOST1)
