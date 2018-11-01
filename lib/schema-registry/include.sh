#!/usr/bin/env bash

checkvar CF_VERSION
checkvar SCHEMA_REGISTRY_HOST
checkvar SCHEMA_REGISTRY_PORT
checkvar AVRO_COMPATIBILITY_LEVEL


CF="${CF_VERSION:0:3}"

export SCHEMA_REGISTRY_URL="http://$SCHEMA_REGISTRY_HOST:$SCHEMA_REGISTRY_PORT"
export AVRO_COMPATIBILITY_LEVEL

if [ "$SCHEMA_REGISTRY_HOST" == "$PRIMARY_IP" ]; then
    required "openjdk8"
    required "kafka"
    required "cftools"
    required "kafka-cli"
    checkvar KAFKA_CONNECTION
    APPLICABLE_SERVICES+=("schema-registry")
fi

install_schema-registry() {
    yum -y -o Dpkg::Options::=--force-confdef install confluent-schema-registry
    continue $? "Could not install schema-registry"
    systemctl daemon-reload
    systemctl enable schema-registry.service
}

start_schema-registry() {
    systemctl start schema-registry.service
    wait_for_endpoint $SCHEMA_REGISTRY_URL 200 30
}

stop_schema-registry() {
    systemctl stop schema-registry.service
}

