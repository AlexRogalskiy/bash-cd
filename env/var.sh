#!/usr/bin/env bash

SERVICES=(
    "cd"
    "zookeeper"
    "kafka"
    "kafka-cli"
    "kafka-topics"
    "schema-registry"
    #
    "librdkafka"
    #
    "grafana"
    "prometheus"
)

HOST1="172.17.0.2"

#required by the example-app
EXAMPLE_APP_SERVERS=($HOST1)
EXAMPLE_APP_BRANCH=master

#required by zookeeper service
ZK_SERVERS=($HOST1)
export ZOOKEEPER_PORT="2181"

#required by kafka services
KAFKA_VERSION=2.0.0
CF_VERSION=5.0.0
KAFKA_SERVERS=($HOST1)
export KAFKA_LOG_DIRS="/data/kafka"
export KAFKA_PROTOCOL="PLAINTEXT"
export KAFKA_REPL_FACTOR=1
export KAFKA_PORT="9092"
#export KAFKA_SASL_MECHANISM=PLAIN
#export KAFKA_AUTHORIZER_CLASS_NAME=kafka.security.auth.SimpleAclAuthorizer
export SCHEMA_REGISTRY_HOST=$HOST1
export SCHEMA_REGISTRY_PORT="8082"
export AVRO_COMPATIBILITY_LEVEL=full_transitive

GRAFANA_SERVERS=($HOST1)
PROMETHEUS_SERVERS=($HOST1)