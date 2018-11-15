#!/usr/bin/env bash

checkvar SCHEMA_REGISTRY_HOST
checkvar SCHEMA_REGISTRY_PORT
checkvar AVRO_COMPATIBILITY_LEVEL

#export SCHEMA_REGISTRY_PUBLIC_URL="https://$PUBLIC_FQN:$SCHEMA_REGISTRY_PORT"
let schema_registry_internal_port=SCHEMA_REGISTRY_PORT+1
export SCHEMA_REGISTRY_INTERNAL_URL="http://$SCHEMA_REGISTRY_HOST:$schema_registry_internal_port"
export AVRO_COMPATIBILITY_LEVEL

if [ "$SCHEMA_REGISTRY_HOST" == "$PRIMARY_IP" ]; then
    required "openjdk8"
    required "k2ssl"
    required "kafka"
    required "cftools"
    required "kafka-cli"
    APPLICABLE_SERVICES+=("schema-registry")
    export PUBLIC_FQN
    export ADMIN_PASSWORD
    export SCHEMA_REGISTRY_PORT
    export KAFKA_SASL_MECHANISM
fi

build_schema-registry() {
    checkvar CF_VERSION
    checkvar KAFKA_CONNECTION
    checkvar ZOOKEEPER_CONNECTION
}

install_schema-registry() {
    apt-get -y -o Dpkg::Options::=--force-confdef install confluent-schema-registry
    continue $? "Could not install schema-registry"
    systemctl daemon-reload
    systemctl enable schema-registry.service
    #Default Schema Registry Account
    kafka-acls --add --allow-principal 'User:schemaregistry' --topic _schemas --consumer --group '*'
    kafka-acls --add --allow-principal 'User:schemaregistry' --topic _schemas --producer --group '*'
    kafka-acls --add --allow-principal 'User:schemaregistry' --topic _schemas --operation DescribeConfigs
    kafka-acls --add --allow-principal 'User:schemaregistry' --topic __consumer_offsets --operation Describe
}

start_schema-registry() {
    #start -q schema-registry
    systemctl start schema-registry.service
    wait_for_endpoint $SCHEMA_REGISTRY_INTERNAL_URL 200 30
}

stop_schema-registry() {
    #stop -q schema-registry
    systemctl stop schema-registry.service
}

