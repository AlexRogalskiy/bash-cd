#!/usr/bin/env bash

checkvar GRAFANA_PORT
checkvar GRAFANA_SERVER

export GRAFANA_PORT
export GRAFANA_URL="http://localhost:$GRAFANA_PORT"
ADMIN_URL="http://admin:admin@localhost:$GRAFANA_PORT"

if [ "$GRAFANA_SERVER" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("grafana")
fi

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
    chown -R grafana:grafana /data/grafana
}

start_grafana() {
    systemctl start grafana-server
    wait_for_endpoint "$GRAFANA_URL" 200 30
    if [ ! -z "$INFLUXDB_URL" ]; then
        curl -s "$ADMIN_URL/api/datasources" -s -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name": "InfluxDB", "type": "influxdb", "access": "proxy", "url": "'$INFLUXDB_URL'", "password": "none", "user": "kafka-metrics", "database": "metrics", "isDefault": true}'
        continue $? "failed to configure default metrics datasource in grafana 1"
        echo ""
    fi
    if [ ! -z "$PROMETHEUS_URL" ]; then
        curl -s "$ADMIN_URL/api/datasources" -s -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name": "Kafka", "type": "prometheus", "access": "proxy", "url": "'$PROMETHEUS_URL'", "password": "none", "user": "none", "isDefault": false, "tlsSkipVerify": true}'
        continue $? "failed to configure default kafka datasource in grafana 1"
        echo ""
    fi

    update_grafana_dashboard "/data/grafana/kafka-groups.static.json"
    update_grafana_dashboard "/data/grafana/kafka-topics.static.json"
}

stop_grafana() {
    systemctl stop grafana-server
}

update_grafana_dashboard() {

    echo "{\"dashboard\":" > /tmp/dashboard.json
    cat "$1" | jq .id=null >> /tmp/dashboard.json
    echo ",\"folderId\": 0, \"overwrite\": true}" >> /tmp/dashboard.json
    curl -s --data-binary "@/tmp/dashboard.json" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -X POST "$ADMIN_URL/api/dashboards/db"
    continue $? "failed to upload grafana dashboard: $1"
    echo ""
}
