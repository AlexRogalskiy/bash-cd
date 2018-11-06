#!/usr/bin/env bash

checkvar KAFKA_LOG_DIRS
checkvar KAFKA_PROTOCOL
checkvar KAFKA_SERVERS
checkvar KAFKA_MEMORY_BUFFER

checkvar ADMIN_PASSWORD

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

   listener="$KAFKA_PROTOCOL://$KAFKA_ADVERTISED_HOST:$this_kafka_port"
   if [ -z "$KAFKA_CONNECTION" ]; then
    KAFKA_CONNECTION="$listener"
   else
    KAFKA_CONNECTION="$KAFKA_CONNECTION,$listener"
   fi

   if [ -z "$KAFKA_INTERNAL_CONNECTION" ]; then
    KAFKA_INTERNAL_CONNECTION="SASL_PLAINTEXT://$kafka_server:19092"
   else
    KAFKA_INTERNAL_CONNECTION="$KAFKA_INTERNAL_CONNECTION,SASL_PLAINTEXT://$kafka_server:19092"
   fi

   if [ "$kafka_server" = "$PRIMARY_IP" ]; then
    if [ "$kafka_server" == "${KAFKA_SERVERS[${#KAFKA_SERVERS[@]}-1]}" ]; then
        is_last_node=1
    fi
    kafka_rolling_restart_wait=$(($i * 10))
    let KAFKA_BROKER_ID=this_broker_id
    let KAFKA_PORT=this_kafka_port
    let KAFKA_JMX_PORT=KAFKA_PORT+20000
    export KAFKA_ADVERTISED_HOST=${KAFKA_ADVERTISED_HOSTS[$i]}
    required "k2ssl"
    required "kafka-distro"
    checkvar KAFKA_PACKAGE
    checkvar KAFKA_MINOR_VERSION
    required "kafka-cli"
    required "zookeeper"
    checkvar ZOOKEEPER_CONNECTION
    APPLICABLE_SERVICES+=("kafka")
    export ADMIN_PASSWORD
    export KAFKA_BROKER_ID
    export KAFKA_LOG_DIRS
    export KAFKA_PROTOCOL
    export KAFKA_REPL_FACTOR
    export KAFKA_MEMORY_BUFFER
    export KAFKA_SASL_MECHANISM
    export KAFKA_AUTHORIZER_CLASS_NAME
    export KAFKA_JMX_PORT
    export KAFKA_PORT
   fi

done

build_kafka() {
    KV=$KAFKA_MINOR_VERSION
    AV="0.9.0"
#    URL="https://oss.sonatype.org/content/repositories/releases/io/amient/affinity/metrics-reporter-kafka_${KV}/${AV}/metrics-reporter-kafka_${KV}-${AV}-all.jar"
#    download "$URL" "$BUILD_DIR/opt/kafka/current/libs/" md5

    URL="https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar"
    download $URL "$BUILD_DIR/opt/" md5
}

install_kafka() {
    chmod 0600 /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/management/jmxremote.password
    systemctl daemon-reload
    systemctl enable kafka.service
}

start_kafka() {
    systemctl start kafka.service
    wait_for_ports $PRIMARY_IP:19092

    if [ $is_last_node -eq 1 ];then
        #Default Admin Account
        kafka-acls --add --allow-principal 'User:admin' --consumer --topic '*' --group '*'
        kafka-acls --add --allow-principal 'User:admin' --producer --topic '*' --group '*'
        kafka-acls --add --allow-principal 'User:admin' --topic '*' --operation DescribeConfigs
        kafka-acls --add --allow-principal 'User:admin' --topic '*' --operation Describe
    fi

}

stop_kafka() {
    sleep $kafka_rolling_restart_wait
    systemctl stop kafka.service
}
