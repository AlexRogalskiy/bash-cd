#!/usr/bin/env bash

SERVICES=(
    "cd"
    "zookeeper"
    "kafka"
    "example-app"
)

HOST0="172.31.3.211"
HOST1="172.31.6.187"
HOST2="172.31.5.41"

#required by the example-app
EXAMPLE_APP_SERVERS=($HOST0)

#required by zookeeper service
ZK_SERVERS=($HOST0)
export ZOOKEEPER_PORT="2181"

#required by kafka services
KAFKA_SERVERS=($HOST1 $HOST2)
export KAFKA_PROTOCOL="PLAINTEXT"
export KAFKA_REPL_FACTOR=2
export KAFKA_PORT="9092"

