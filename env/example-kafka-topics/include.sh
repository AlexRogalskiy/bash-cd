#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar KAFKA_SERVERS

server="${KAFKA_SERVERS[${#KAFKA_SERVERS[@]}-1]}"
if [ "$server" == "$PRIMARY_IP" ]; then
    required "kafka-cli"
    APPLICABLE_SERVICES+=("kafka-topics")
fi

install_kafka-topics() {
    ##FIXME topic-assignments.json is specific to environment so we should create kafka-cli/rebalance <topic>
    ##
    #kafka-reassign-partitions --reassignment-json-file /etc/kafka/topic-assignments.json --execute
    /opt/kafka/acls.sh
    /opt/kafka/quotas.sh
}