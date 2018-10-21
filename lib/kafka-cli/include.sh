#!/usr/bin/env bash

required "zookeeper"    ZOOKEEPER_CONNECTION
required "kafka"        KAFKA_CONNECTION

for i in "${!KAFKA_SERVERS[@]}"
do
   server="${KAFKA_SERVERS[$i]}"
   if [ "$server" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("kafka-cli")
   fi
done

function install_kafka-cli() {
    checkvar KAFKA_VERSION
    KV="${KAFKA_VERSION:0:3}"
    #TODO https://github.com/amient/bash-cd/issues/18
    rm  /opt/kafka/current/libs/avro-formatter-kafka-*
    URL="https://oss.sonatype.org/content/repositories/snapshots/io/amient/affinity/avro-formatter-kafka_${KV}-scala_2.11/0.8.2-SNAPSHOT/avro-formatter-kafka_$KV-scala_2.11-0.8.2-20180925.150459-3-all.jar"
    download "$URL" "/opt/kafka/current/libs/"
    continue $? "failed to install avro formatter jar"
}
