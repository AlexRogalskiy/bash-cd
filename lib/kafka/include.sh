#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar ZOOKEEPER_CONNECTION
checkvar KAFKA_LOG_DIRS
checkvar KAFKA_PROTOCOL
checkvar KAFKA_SERVERS
checkvar KAFKA_PORT
checkvar KAFKA_VERSION

export KAFKA_BROKER_ID
export KAFKA_LOG_DIRS
export KAFKA_PROTOCOL
export KAFKA_REPL_FACTOR
export KAFKA_SASL_MECHANISM
export KAFKA_AUTHORIZER_CLASS_NAME

export KAFKA_CONNECTION
export KAFKA_INTER_BROKER_VERSION=${KAFKA_VERSION:0:3}
export KAFKA_LOG_FORMAT_VERSION=${KAFKA_VERSION:0:3}

KAFKA_BROKER_ID_OFFSET="${KAFKA_BROKER_ID_OFFSET:-0}"

for i in "${!KAFKA_SERVERS[@]}"
do
   server="${KAFKA_SERVERS[$i]}"
   if [ "$server" == "$PRIMARY_IP" ]; then
    required "kafka-distro"
    checkvar KAFKA_PACKAGE
    export KAFKA_PACKAGE
    required "kafka-cli"
    APPLICABLE_SERVICES+=("kafka")
    let KAFKA_BROKER_ID=i+1+KAFKA_BROKER_ID_OFFSET
    export KAFKA_BROKER_ID
    export KAFKA_PORT
    let KAFKA_JMX_PORT=KAFKA_PORT+20000
    export KAFKA_JMX_PORT
   fi

   export KAFKA_ADVERTISED_HOST="${KAFKA_ADVERTISED_HOSTS[$i]}"
   if [ -z "$KAFKA_ADVERTISED_HOST" ] ; then
       KAFKA_ADVERTISED_HOST=$server
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
    checkvar KAFKA_PACKAGE
    export KAFKA_PACKAGE
    download https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar $BUILD_DIR/opt/
    #TODO checksum the prometheus agent download
}

install_kafka() {
    checkvar KAFKA_VERSION
    KV="${KAFKA_VERSION:0:3}"
    URL="https://oss.sonatype.org/content/repositories/snapshots/io/amient/affinity/metrics-reporter-kafka_${KV}/0.8.2-SNAPSHOT/metrics-reporter-kafka_${KV}-0.8.2-20181025.155900-1-all.jar"
    download "$URL" "/opt/kafka/current/libs/"
    continue $? "failed to download metrics reporter jar"
    MD5_FILE="metrics-reporter-kafka_$KV-0.8.2-20181025.155900-1-all.jar.md5"
    MD5_URL="https://oss.sonatype.org/content/repositories/snapshots/io/amient/affinity/metrics-reporter-kafka_${KV}/0.8.2-SNAPSHOT/$MD5_FILE"
    download "$MD5_URL" "/opt/kafka/current/libs/"
    continue $? "failed to download metrics reporter checksum file"
    local="$(checksum "/opt/kafka/current/libs/metrics-reporter-kafka_$KV-0.8.2-20181025.155900-1-all.jar")"
    remote=$(cat "/opt/kafka/current/libs/$MD5_FILE")
    if [[ "$local"  != $remote* ]]; then
     rm -f /opt/kafka/current/libs/metrics-reporter-kafka*
     fail "metrics reporter checksum failed"
    fi

    chmod 0600 /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/management/jmxremote.password
    systemctl daemon-reload
    systemctl enable kafka.service
}

start_kafka() {
    systemctl start kafka.service
}

stop_kafka() {
    systemctl stop kafka.service
}
