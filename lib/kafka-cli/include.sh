#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar ZOOKEEPER_CONNECTION
checkvar KAFKA_CONNECTION

APPLICABLE_SERVICES+=("kafka-cli")

