#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar KAFKA_SERVERS

server="${KAFKA_SERVERS[${#KAFKA_SERVERS[@]}-1]}"
if [ "$server" == "$PRIMARY_IP" ]; then
    required "kafka-cli"
    APPLICABLE_SERVICES+=("kafka-topics")
fi

install_kafka-topics() {
    /opt/kafka/topics.sh
    continue $? "could not apply kafka topics.sh"
    /opt/kafka/acls.sh
    continue $? "could not apply kafka acl.sh"
    /opt/kafka/quotas.sh
    continue $? "could not apply kafka quotas.sh"
    if [ -f /etc/kafka/topic-assignments.json ]; then
        kafka-reassign-partitions --reassignment-json-file /etc/kafka/topic-assignments.json --execute
    fi
}