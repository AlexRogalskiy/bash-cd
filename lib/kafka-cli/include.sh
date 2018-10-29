#!/usr/bin/env bash

required "zookeeper"
required "kafka"

checkvar ZOOKEEPER_CONNECTION
checkvar KAFKA_CONNECTION
checkvar KAFKA_VERSION

APPLICABLE_SERVICES+=("kafka-cli")
#export AFFINITY_HOME="/opt/affinity"

function install_kafka-cli() {
    checkvar KAFKA_VERSION
    KV="${KAFKA_VERSION:0:3}"
    rm -f /opt/kafka/current/libs/avro-formatter-kafka-*
    URL="https://oss.sonatype.org/content/repositories/snapshots/io/amient/affinity/avro-formatter-kafka_${KV}-scala_2.11/0.8.2-SNAPSHOT/avro-formatter-kafka_$KV-scala_2.11-0.8.2-20180925.150459-3-all.jar"
    download "$URL" "/opt/kafka/current/libs/"
    continue $? "failed to download avro formatter jar"
    MD5_FILE="avro-formatter-kafka_$KV-scala_2.11-0.8.2-20180925.150459-3-all.jar.md5"
    MD5_URL="https://oss.sonatype.org/content/repositories/snapshots/io/amient/affinity/avro-formatter-kafka_${KV}-scala_2.11/0.8.2-SNAPSHOT/$MD5_FILE"
    download "$MD5_URL" "/opt/kafka/current/libs/"
    continue $? "failed to download avro formatter checksum file"
    local="$(checksum "/opt/kafka/current/libs/avro-formatter-kafka_$KV-scala_2.11-0.8.2-20180925.150459-3-all.jar")"
    remote=$(cat "/opt/kafka/current/libs/$MD5_FILE")
    if [[ "$local"  != $remote* ]]; then
     fail "avro formatter checksum failed"
    fi

    #TODO replace this with dwonloaded affinity-cli.jar
#    git_clone_or_update https://github.com/amient/affinity.git "$AFFINITY_HOME" "master"
}
