#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar ZOOKEEPER_CONNECTION
checkvar KAFKA_PROTOCOL
checkvar KAFKA_SERVERS
checkvar KAFKA_PORT

export KAFKA_BROKER_ID
export KAFKA_CONNECTION
for i in "${!KAFKA_SERVERS[@]}"
do
   server="${KAFKA_SERVERS[$i]}"
   if [ "$server" == "$PRIMARY_IP" ]; then
    required "kafka-distro"
    APPLICABLE_SERVICES+=("kafka")
    let KAFKA_BROKER_ID=i+1
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

start_kafka() {
    start -q kafka
}

stop_kafka() {
    stop -q kafka
}

