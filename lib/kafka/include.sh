#!/usr/bin/env bash

checkvar KAFKA_LOG_DIRS
checkvar KAFKA_PROTOCOL
checkvar KAFKA_SERVERS
checkvar KAFKA_MEMORY_BUFFER

export KAFKA_CONNECTION=""
export KAFKA_INTERNAL_CONNECTION=""
export KAFKA_INTER_BROKER_VERSION=${KAFKA_VERSION%.*}
export KAFKA_LOG_FORMAT_VERSION=${KAFKA_VERSION%.*}

KAFKA_BROKER_ID_OFFSET="${KAFKA_BROKER_ID_OFFSET:-0}"

is_last_node=0
for i in "${!KAFKA_SERVERS[@]}"
do
   kafka_server="${KAFKA_SERVERS[$i]}"

   let this_broker_id=i+1+KAFKA_BROKER_ID_OFFSET
   let this_kafka_port=9091+i

   listener="$KAFKA_PROTOCOL://$kafka_server:$this_kafka_port"
   if [ -z "$KAFKA_CONNECTION" ]; then
    KAFKA_CONNECTION="$listener"
   else
    KAFKA_CONNECTION="$KAFKA_CONNECTION,$listener"
   fi

   if [ -z "$KAFKA_INTERNAL_CONNECTION" ]; then
    KAFKA_INTERNAL_CONNECTION="PLAINTEXT://$kafka_server:19092"
   else
    KAFKA_INTERNAL_CONNECTION="$KAFKA_INTERNAL_CONNECTION,PLAINTEXT://$kafka_server:19092"
   fi

   if [ "$kafka_server" = "$PRIMARY_IP" ]; then
    if [ "$kafka_server" == "${KAFKA_SERVERS[${#KAFKA_SERVERS[@]}-1]}" ]; then
        is_last_node=1
    fi
    kafka_rolling_restart_wait=$(($i * 10))
    let KAFKA_BROKER_ID=this_broker_id
    let KAFKA_PORT=this_kafka_port
    let KAFKA_JMX_PORT=KAFKA_PORT+20000

    required "kafka-distro"
    checkvar KAFKA_PACKAGE
    checkvar KAFKA_MINOR_VERSION
    required "kafka-cli"
    required "zookeeper"
    checkvar ZOOKEEPER_CONNECTION
    APPLICABLE_MODULES+=("kafka")
    export ADMIN_PASSWORD
    export KAFKA_BROKER_ID
    export KAFKA_LOG_DIRS
    export KAFKA_PROTOCOL
    export KAFKA_REPL_FACTOR
    export KAFKA_MEMORY_BUFFER
    export KAFKA_SASL_MECHANISM
    export KAFKA_JMX_PORT
    export KAFKA_PORT
   fi

done

rolling_kafka() {
    return 1
}

build_kafka() {

    checkvar AFFINITY_VERSION
    checkvar KAFKA_PACKAGE
    checkvar KAFKA_VERSION
    checkvar KAFKA_MINOR_VERSION
    checkvar ZOOKEEPER_CONNECTION

     #export versions
    export KAFKA_INTER_BROKER_VERSION=${KAFKA_VERSION%.*}
    export KAFKA_LOG_FORMAT_VERSION=${KAFKA_VERSION%.*}

    #systemctl is-active --quiet kafka
}

install_kafka() {
    KV=$KAFKA_MINOR_VERSION
    AV=$AFFINITY_VERSION
    if [ ! -d "/opt/kafka/current/libs" ]; then
        fail "/opt/kafka/current/libs doesn't exist"
    fi
    URL="https://oss.sonatype.org/content/repositories/releases/io/amient/affinity/metrics-reporter-kafka_${KV}/${AV}/metrics-reporter-kafka_${KV}-${AV}-all.jar"
    download "$URL" "/opt/kafka/current/libs/" md5

    URL="https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.10/jmx_prometheus_javaagent-0.10.jar"
    download $URL "/opt/" md5

    systemctl daemon-reload
    systemctl enable kafka.service

    mkdir -p $KAFKA_LOG_DIRS
    continue $? "could not create $KAFKA_LOG_DIRS"
}

start_kafka() {
    systemctl start kafka.service
    wait_for_ports 45 $PRIMARY_IP:$KAFKA_PORT
}

stop_kafka() {
    systemctl stop kafka.service
}
