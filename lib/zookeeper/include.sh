#!/usr/bin/env bash

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
   if [ -z "$ZOOKEEPER_CONNECTION" ]; then
    ZOOKEEPER_CONNECTION="$server:$ZOOKEEPER_PORT"
   else
    ZOOKEEPER_CONNECTION="$ZOOKEEPER_CONNECTION,$server:$ZOOKEEPER_PORT"
   fi
   ZK_PEERS="${ZK_PEERS}server.${server_id}=$server:2888:3888\\\\n"
   if [ "$server" == "$PRIMARY_IP" ]; then
    required "kafka-distro"
    required "kafka-cli"
    APPLICABLE_SERVICES+=("zookeeper")
    ZK_MY_ID="$server_id"
   fi
done

install_zookeeper() {
    systemctl daemon-reload
    systemctl enable zookeeper.service
}

start_zookeeper() {
    #start -q zookeeper
    systemctl start -q zookeeper.service
}

stop_zookeeper() {
    #stop -q zookeeper
    systemctl stop -q zookeeper.service
}
