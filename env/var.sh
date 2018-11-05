#!/usr/bin/env bash

KAFKA_VERSION=2.0.0


SERVICES=(
    "cd"
    "gitd"
    "zookeeper"
    "kafka"
    "kafka-topics"
    "schema-registry"
    "grafana"
    "prometheus"
)

HOST1=172.17.0.2

GIT_SERVER=$HOST1
GIT_SERVER_DATA_DIR=/data/git

ZK_SERVERS=($HOST1)
ZOOKEEPER_PORT=2181

SCHEMA_REGISTRY_HOST=$HOST1
SCHEMA_REGISTRY_PORT=8081
AVRO_COMPATIBILITY_LEVEL=full_transitive

KAFKA_SERVERS=($HOST1)
KAFKA_ADVERTISED_HOSTS=(localhost)
KAFKA_LOG_DIRS="/data/kafka"
KAFKA_PROTOCOL="SASL_PLAINTEXT"
KAFKA_REPL_FACTOR=1
KAFKA_MEMORY_BUFFER=1073741824
KAFKA_PORT=9092
KAFKA_SASL_MECHANISM=PLAIN
KAFKA_AUTHORIZER_CLASS_NAME=kafka.security.auth.SimpleAclAuthorizer

GRAFANA_SERVER=$HOST1
GRAFANA_PORT=8300
GRAFANA_EDITABLE="true"
PROMETHEUS_SERVERS=($HOST1)
PROMETHEUS_DATA_DIR=/data/prometheus/
PROMETHEUS_RETENTION=7d
