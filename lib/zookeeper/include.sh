#!/usr/bin/env bash

required "kafka-distro"
required "kafka-cli"

checkvar PRIMARY_IP
checkvar ZK_SERVERS
checkvar ZOOKEEPER_PORT

export ZOOKEEPER_CONNECTION
export ZK_MY_ID
export ZK_PEERS
for i in "${!ZK_SERVERS[@]}"
do
   let server_id=(i+1)
   server="${ZK_SERVERS[$i]}"
   if [ "$server" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("zookeeper")
    ZK_MY_ID="$server_id"
   fi
   if [ -z "$ZOOKEEPER_CONNECTION" ]; then
    ZOOKEEPER_CONNECTION="$server:$ZOOKEEPER_PORT"
   else
    ZOOKEEPER_CONNECTION="$ZOOKEEPER_CONNECTION,$server:$ZOOKEEPER_PORT"
   fi
   ZK_PEERS="${ZK_PEERS}server.${server_id}=$server:2888:3888\\\\n"
done
checkvar ZOOKEEPER_CONNECTION

start_zookeeper() {
    start -q zookeeper
}

stop_zookeeper() {
    stop -q zookeeper
}
