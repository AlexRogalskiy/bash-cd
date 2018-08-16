#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar ZOOKEEPER_CONNECTION
checkvar KAFKA_LOG_DIRS
checkvar KAFKA_PROTOCOL
checkvar KAFKA_SERVERS
checkvar KAFKA_PORT
checkvar KAFKA_VERSION
checkvar KAFKA_PACKAGE

export KAFKA_PACKAGE
export KAFKA_BROKER_ID
export KAFKA_CONNECTION=""
export KAFKA_INTER_BROKER_VERSION=${KAFKA_VERSION:0:3}
export KAFKA_LOG_FORMAT_VERSION=${KAFKA_VERSION:0:3}

KAFKA_BROKER_ID_OFFSET="${KAFKA_BROKER_ID_OFFSET:-0}"

for i in "${!KAFKA_SERVERS[@]}"
do
   server="${KAFKA_SERVERS[$i]}"
   if [ "$server" == "$PRIMARY_IP" ]; then
    required "kafka-distro"
    APPLICABLE_SERVICES+=("kafka")
    let KAFKA_BROKER_ID=i+1+KAFKA_BROKER_ID_OFFSET
   fi
   listener="$KAFKA_PROTOCOL://$server:$KAFKA_PORT"
   if [ -z "$KAFKA_CONNECTION" ]; then
    KAFKA_CONNECTION="$listener"
   else
    KAFKA_CONNECTION="$KAFKA_CONNECTION,$listener"
   fi
done

build_kafka() {
    checkvar KAFKA_BROKER_ID
    checkvar KAFKA_REPL_FACTOR
}

install_kafka() {
    systemctl daemon-reload
    systemctl enable kafka.service
}

start_kafka() {
    #start -q kafka
    systemctl start kafka.service
}

stop_kafka() {
    #stop -q kafka
    systemctl stop kafka.service
}

