#!/usr/bin/env bash

checkvar GRAFANA_SERVERS
#FIXME disable grafana password on install
export GRAFANA_URL="http://admin:admin@localhost:3000"

for i in "${!GRAFANA_SERVERS[@]}"
do
   server="${GRAFANA_SERVERS[$i]}"
   if [ "$server" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("grafana")
   fi
done

setup_grafana() {
    curl -s https://packagecloud.io/gpg.key | apt-key add -
    continue $? "could not add packagecloud repo key"
    add-apt-repository "deb https://packagecloud.io/grafana/stable/debian/ stretch main"
    apt-get -y update
    continue $? "could not add grafana debian repository"
    apt-cache policy grafana
}

install_grafana() {
    apt-get -y install grafana
}

start_grafana() {
    systemctl start grafana-server
    wait_for_endpoint http://localhost:3000 302 30
    if [ ! -z "$INFLUXDB_URL" ]; then
        curl -s "$GRAFANA_URL/api/datasources" -s -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name": "InfluxDB", "type": "influxdb", "access": "proxy", "url": "'$INFLUXDB_URL'", "password": "none", "user": "kafka-metrics", "database": "metrics", "isDefault": true}'
    fi
    if [ ! -z "$PROMETHEUS_URL" ]; then
        curl -s "$GRAFANA_URL/api/datasources" -s -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name": "InfluxDB", "type": "prometheus", "access": "proxy", "url": "'$INFLUXDB_URL'", "password": "none", "user": "kafka-metrics", "database": "metrics", "isDefault": true}'
    fi
    continue $? "failed to configure default metrics datasource in grafana 1"
}

stop_grafana() {
    systemctl stop grafana-server
}

