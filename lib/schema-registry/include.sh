#!/usr/bin/env bash

checkvar SCHEMA_REGISTRY_HOST
checkvar SCHEMA_REGISTRY_PORT

export SCHEMA_REGISTRY_URL="http://$SCHEMA_REGISTRY_HOST:$SCHEMA_REGISTRY_PORT"

if [ "$SCHEMA_REGISTRY_HOST" == "$PRIMARY_IP" ]; then
    required "kafka" KAFKA_CONNECTION
    APPLICABLE_SERVICES+=("schema-registry")
fi

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

