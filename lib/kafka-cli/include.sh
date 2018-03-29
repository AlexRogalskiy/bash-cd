#!/usr/bin/env bash

required "zookeeper"    ZOOKEEPER_CONNECTION
required "kafka"        KAFKA_CONNECTION

APPLICABLE_SERVICES+=("kafka-cli")

