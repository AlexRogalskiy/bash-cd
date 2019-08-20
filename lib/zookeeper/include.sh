#!/usr/bin/env bash

checkvar ZK_SERVERS
checkvar ZOOKEEPER_PORT

export ZOOKEEPER_CONNECTION=""
export ZK_PEERS=""

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
    APPLICABLE_MODULES+=("zookeeper")
    export ZK_MY_ID="$server_id"
    export ZOOKEEPER_PORT
    export ZK_PEERS
   fi
done

build_zookeeper() {
  systemctl is-active --quiet zookeeper
}

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
