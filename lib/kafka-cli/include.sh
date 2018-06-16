#!/usr/bin/env bash

required "zookeeper"    ZOOKEEPER_CONNECTION
required "kafka"        KAFKA_CONNECTION

export AFFINITY_HOME="/opt/affinity"

for i in "${!KAFKA_SERVERS[@]}"
do
   server="${KAFKA_SERVERS[$i]}"
   if [ "$server" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("kafka-cli")
   fi
done

function install_kafka-cli() {
    git_clone_or_update https://github.com/amient/affinity.git "$AFFINITY_HOME" "master"
}
