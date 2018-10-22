#!/usr/bin/env bash

checkvar GRAFANA_SERVERS

for i in "${!KAFKA_SERVERS[@]}"
do
   server="${KAFKA_SERVERS[$i]}"
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
}

stop_grafana() {
    systemctl stop grafana-server
}

