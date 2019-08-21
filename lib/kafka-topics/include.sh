#!/usr/bin/env bash

checkvar KAFKA_SERVERS
checkvar KAFKA_CONNECTION

server="${KAFKA_SERVERS[${#KAFKA_SERVERS[@]}-1]}"
if [ "$server" == "$PRIMARY_IP" ]; then
    apply "kafka-cli"
    apply "kafka-topics"
fi

install_kafka-topics() {
    wait_for_ports $KAFKA_INTERNAL_CONNECTION
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