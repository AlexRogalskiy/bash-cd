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
    cd $AFFINITY_HOME
    echo "installing avro formatter.."
    ./gradlew --no-daemon :kafka:avro-formatter-kafka:build --exclude-task test
    rm  /opt/kafka/current/libs/avro-formatter-kafka-*
    cp ./kafka/avro-formatter-kafka/build/lib/avro-formatter-kafka-*-all.jar /opt/kafka/current/libs/
}
