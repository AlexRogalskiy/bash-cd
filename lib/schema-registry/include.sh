#!/usr/bin/env bash

checkvar SCHEMA_REGISTRY_HOST
checkvar SCHEMA_REGISTRY_PORT
checkvar AVRO_COMPATIBILITY_LEVEL

export SCHEMA_REGISTRY_URL="http://$SCHEMA_REGISTRY_HOST:$SCHEMA_REGISTRY_PORT"

if [ "$SCHEMA_REGISTRY_HOST" == "$PRIMARY_IP" ]; then
    required "openjdk8"
    required "kafka" KAFKA_CONNECTION
    APPLICABLE_SERVICES+=("schema-registry")
fi

setup_schema-registry() {
    wget -qO - https://packages.confluent.io/deb/4.0/archive.key | sudo apt-key add -
    add-apt-repository -y "deb [arch=amd64] https://packages.confluent.io/deb/4.0 stable main"
    add-apt-repository -y ppa:openjdk-r/ppa
    apt-get -y update
}

install_schema-registry() {
    #TODO schema registry should be built from sources (but probably the amient fork which has auto-build fixes)
    apt-get -y install confluent-schema-registry
    systemctl daemon-reload
    systemctl enable schema-registry.service
}

start_schema-registry() {
    #start -q schema-registry
    systemctl start schema-registry.service
}

stop_schema-registry() {
    #stop -q schema-registry
    systemctl stop schema-registry.service
}

