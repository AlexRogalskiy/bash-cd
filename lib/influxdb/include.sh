#!/usr/bin/env bash

checkvar INFLUXDB_SERVER

export INFLUXDB_URL="http://$INFLUXDB_SERVER:8086"

if [ "$INFLUXDB_SERVER" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("influxdb")
    export INFLUXDB_DATA_DIR
fi

setup_influxdb() {
    curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
    source /etc/lsb-release
    echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
    apt-get -y update
}

install_influxdb() {
    apt-get -y -o Dpkg::Options::=--force-confdef install influxdb
    systemctl unmask influxdb.service
    mkdir -p $INFLUXDB_DATA_DIR
    echo $INFLUXDB_DATA_DIR
    chown influxdb:influxdb "$INFLUXDB_DATA_DIR"
}

start_influxdb() {
    systemctl start influxdb
    wait_for_endpoint "$INFLUXDB_URL/ping" 204 30
    echo "influxdb endpoint check successful"
    curl -G "$INFLUXDB_URL/query" --data-urlencode "q=CREATE DATABASE metrics"
    continue "failed to create influxdb metrics database"
}

stop_influxdb() {
    systemctl stop influxdb
}

