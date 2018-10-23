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
    "librdkafka"
    #
    "grafana"
    "prometheus"
)


HOSTM="172.172.0.1"
HOSTZ0="172.172.0.10"
HOSTK1="172.172.0.11"
HOSTK2="172.172.0.12"
HOSTK3="172.172.0.13"

ZK_SERVERS=($HOSTZ0)
export ZOOKEEPER_PORT="2181"
export SCHEMA_REGISTRY_HOST=$HOSTZ0
export SCHEMA_REGISTRY_PORT="8082"
export AVRO_COMPATIBILITY_LEVEL=full_transitive

KAFKA_SERVERS=($HOSTK1 $HOSTK2 $HOSTK3)
export KAFKA_LOG_DIRS="/data/kafka"
export KAFKA_PROTOCOL="PLAINTEXT"
export KAFKA_REPL_FACTOR=2
export KAFKA_PORT="9092"
#export KAFKA_SASL_MECHANISM=PLAIN
#export KAFKA_AUTHORIZER_CLASS_NAME=kafka.security.auth.SimpleAclAuthorizer

GRAFANA_SERVERS=($HOSTM)
PROMETHEUS_SERVERS=($HOSTM)
