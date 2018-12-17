#!/usr/bin/env bash

checkvar GRAFANA_PORT
checkvar GRAFANA_SERVER
checkvar GRAFANA_EDITABLE
checkvar ADMIN_PASSWORD

export GRAFANA_PORT
export GRAFANA_URL="http://$GRAFANA_SERVER:$GRAFANA_PORT"
ADMIN_URL="http://admin:admin@localhost:$GRAFANA_PORT"

if [ "$GRAFANA_SERVER" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("grafana")
fi

function setup_grafana() {
    curl -s https://packagecloud.io/gpg.key | apt-key add -
    continue $? "could not add packagecloud repo key"
    add-apt-repository "deb https://packagecloud.io/grafana/stable/debian/ stretch main"
    continue $? "could not add grafana debian repository"
    apt-get -y update
    apt-cache policy grafana
    apt-get -y install jq
    continue $? "could not install jq tool for processing grafana dashboards"
    apt-get -y -o Dpkg::Options::=--force-confdef install grafana
}

function build_grafana() {
    no_expand data
}

function install_grafana() {
    chown -R grafana:grafana /data/grafana
    systemctl enable grafana-server
}

function start_grafana() {
    systemctl start grafana-server
    wait_for_endpoint "$GRAFANA_URL" 200 30

    #first change admin password
    curl -s --data "{\"oldPassword\": \"admin\",\"newPassword\": \"$ADMIN_PASSWORD\",\"confirmNew\": \"$ADMIN_PASSWORD\"}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -X PUT "http://admin:admin@localhost:$GRAFANA_PORT/api/user/password"
    continue $? "failed to set default grafana admin password"


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
    update_grafana_dashboard() {

        echo "{\"dashboard\":" > /tmp/dashboard.json
        cat "$1" | jq ".id=null|.time.from=\"now-1h\"|.time.to=\"now\"|.refresh=\"5s\"|.editable=$GRAFANA_EDITABLE|.panels[].editable=$GRAFANA_EDITABLE" >> /tmp/dashboard.json
        echo ",\"folderId\": 0, \"overwrite\": true}" >> /tmp/dashboard.json
        curl -s --data-binary "@/tmp/dashboard.json" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -X POST "$ADMIN_URL/api/dashboards/db"
        continue $? "failed to upload grafana dashboard: $1"
        echo ""
    }
    update_grafana_dashboard "/data/grafana/kafka-groups.static.json"
    update_grafana_dashboard "/data/grafana/kafka-topics.static.json"
    update_grafana_dashboard "/data/grafana/kafka-overview.static.json"
}

function stop_grafana() {
    systemctl stop grafana-server
}

