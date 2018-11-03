#!/usr/bin/env bash

checkvar CF_VERSION
checkvar SCHEMA_REGISTRY_HOST
checkvar SCHEMA_REGISTRY_PORT
checkvar AVRO_COMPATIBILITY_LEVEL

export SCHEMA_REGISTRY_URL="http://$SCHEMA_REGISTRY_HOST:$SCHEMA_REGISTRY_PORT"
export AVRO_COMPATIBILITY_LEVEL

if [ "$SCHEMA_REGISTRY_HOST" == "$PRIMARY_IP" ]; then
    required "openjdk8"
    required "kafka"
    required "cftools"
    required "kafka-cli"
    APPLICABLE_SERVICES+=("schema-registry")
fi

#setup_schema-registry() {
#    add-apt-repository -y ppa:openjdk-r/ppa
#    apt-get -y update
#}

build_schema-registry() {
    checkvar KAFKA_CONNECTION
    checkvar ZOOKEEPER_CONNECTION
}

install_schema-registry() {
    apt-get -y -o Dpkg::Options::=--force-confdef install confluent-schema-registry
    continue $? "Could not install schema-registry"
    systemctl daemon-reload
    systemctl enable schema-registry.service
}

start_schema-registry() {
    #start -q schema-registry
    systemctl start schema-registry.service
    wait_for_endpoint $SCHEMA_REGISTRY_URL 200 30
}

stop_schema-registry() {
    #stop -q schema-registry
    systemctl stop schema-registry.service
}

