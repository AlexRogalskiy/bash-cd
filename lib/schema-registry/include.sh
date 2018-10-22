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
    curl -s https://packages.confluent.io/deb/$CF/archive.key | apt-key add -
    continue $? "could not add confluent repo key"
    #wget -qO - https://packages.confluent.io/deb/$CF/archive.key | sudo apt-key add -
    add-apt-repository -y "deb [arch=amd64] https://packages.confluent.io/deb/$CF stable main"
    add-apt-repository -y ppa:openjdk-r/ppa
    apt-get -y update
    continue $? "could not add confluent repository"
}

install_schema-registry() {
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

