#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar ZK_SERVERS
checkvar ZOOKEEPER_PORT

export ZOOKEEPER_PORT
export ZOOKEEPER_CONNECTION=""
export ZK_MY_ID
export ZK_PEERS

for z in "${!ZK_SERVERS[@]}"
do
   let server_id=(z+1)
   zk_server="${ZK_SERVERS[$z]}"
   if [ -z "$ZOOKEEPER_CONNECTION" ]; then
    ZOOKEEPER_CONNECTION="$zk_server:$ZOOKEEPER_PORT"
   else
    ZOOKEEPER_CONNECTION="$ZOOKEEPER_CONNECTION,$zk_server:$ZOOKEEPER_PORT"
   fi
   ZK_PEERS="${ZK_PEERS}server.${server_id}=$zk_server:2888:3888\n"
   if [ "$zk_server" == "$PRIMARY_IP" ]; then
    required "kafka-distro"
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
