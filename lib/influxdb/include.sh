#!/usr/bin/env bash

checkvar INFLXUDB_SERVER

if [ "$INFLXUDB_SERVER" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("prometheus")
fi

build_infuxdb() {
    VERSION=2.4.3
}

#install_influxdb() {
#}

start_prometheus() {
    systemctl start influxdb
    wait_for_endpoint http://localhost:9090 302 15
}

stop_prometheus() {
    systemctl stop influxdb
}

