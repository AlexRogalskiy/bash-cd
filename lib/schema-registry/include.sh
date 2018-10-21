#!/usr/bin/env bash

checkvar CF_VERSION
checkvar SCHEMA_REGISTRY_HOST
checkvar SCHEMA_REGISTRY_PORT
checkvar AVRO_COMPATIBILITY_LEVEL

CF="${CF_VERSION:0:3}"

export SCHEMA_REGISTRY_URL="http://$SCHEMA_REGISTRY_HOST:$SCHEMA_REGISTRY_PORT"

if [ "$SCHEMA_REGISTRY_HOST" == "$PRIMARY_IP" ]; then
    required "openjdk8"
    required "kafka" KAFKA_CONNECTION
    APPLICABLE_SERVICES+=("schema-registry")
fi

setup_schema-registry() {
    wget -qO - https://packages.confluent.io/deb/5.0/archive.key | sudo apt-key add -
    add-apt-repository -y "deb [arch=amd64] https://packages.confluent.io/deb/$CF stable main"
    add-apt-repository -y ppa:openjdk-r/ppa
    apt-get -y update
}

install_schema-registry() {
    #TODO schema registry should be built from sources (but probably the amient fork which has auto-build fixes)
    apt-get -y install confluent-schema-registry
    continue $? "Could not install schema-registry"
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

