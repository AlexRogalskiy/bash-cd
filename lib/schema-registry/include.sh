#!/usr/bin/env bash

checkvar KAFKA_CONNECTION
checkvar SCHEMA_REGISTRY_HOST
checkvar SCHEMA_REGISTRY_PORT

export SCHEMA_REGISTRY_URL="http://$SCHEMA_REGISTRY_HOST:$SCHEMA_REGISTRY_PORT"
if [ "$SCHEMA_REGISTRY_HOST" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("schema-registry")
fi
checkvar SCHEMA_REGISTRY_URL


start_schema-registry() {
    start -q schema-registry
}

stop_schema-registry() {
    stop -q schema-registry
}

install_schema-registry() {
    #TODO schema registry should be built from sources (but probably the amient fork which has auto-build fixes)
    apt-get install -y confluent-schema-registry
}