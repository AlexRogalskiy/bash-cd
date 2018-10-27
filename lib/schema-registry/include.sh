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
    required "cftools"
    APPLICABLE_SERVICES+=("schema-registry")
    export AVRO_COMPATIBILITY_LEVEL
fi

#setup_schema-registry() {
#    add-apt-repository -y ppa:openjdk-r/ppa
#    apt-get -y update
#}

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

