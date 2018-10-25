#!/usr/bin/env bash

checkvar PROMETHEUS_SERVERS

export PROMETHEUS_URL

if [ ! -z "$KAFKA_JMX_PROMETHEUS_PORT" ]; then
    for i in "${!PROMETHEUS_SERVERS[@]}"
    do
       server="${PROMETHEUS_SERVERS[$i]}"
       if [ "$server" == "$PRIMARY_IP" ]; then
        APPLICABLE_SERVICES+=("prometheus")
        if [ ! -z "$KAFKA_SERVERS" ]; then
            export KAFKA_PROMETHEUS_TARGETS
            for i in "${!KAFKA_SERVERS[@]}"
            do
               kafka_host="${KAFKA_ADVERTISED_HOSTS[$i]}"
               export KAFKA_PROMETHEUS_TARGETS="${KAFKA_PROMETHEUS_TARGETS} ${kafka_host}:$KAFKA_JMX_PROMETHEUS_PORT,"
            done
        fi
       fi
    done
fi

build_prometheus() {
    VERSION=2.4.3
    DOWNLOAD="prometheus-$VERSION.linux-amd64"
    download "https://github.com/prometheus/prometheus/releases/download/v$VERSION/$DOWNLOAD.tar.gz" /opt/
    continue $? "failed to download prometheus"
    SHA256="$(sha256sum "/opt/$DOWNLOAD.tar.gz")"
    if [[ "$SHA256"  != 3aa063498ab3b4d1bee103d80098ba33d02b3fed63cb46e47e1d16290356db8a* ]]; then
     rm "/opt/$DOWNLOAD.tar.gz"
     fail "prometheus checksum failed"
    fi
    cd /opt
    if [ ! -d "/opt/$DOWNLOAD" ]; then
            tar xvf "/opt/$DOWNLOAD.tar.gz"
            continue $? "could not untar prometheus download"
    fi
    ln -sf /opt/$DOWNLOAD prometheus
}

install_prometheus() {
    id -u prometheus > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        useradd --no-create-home --shell /bin/false prometheus
        useradd --no-create-home --shell /bin/false node_exporter
    fi
    mkdir -p /var/lib/prometheus
    chown -R prometheus:prometheus /var/lib/prometheus
    continue $? "failed to create prometheus user"
    chown prometheus:prometheus /opt/prometheus/prometheus
    chown prometheus:prometheus /opt/prometheus/promtool
    cp -r /opt/prometheus/consoles /etc/prometheus
    cp -r /opt/prometheus/console_libraries /etc/prometheus
    chown -R prometheus:prometheus /etc/prometheus
    systemctl daemon-reload
}

start_prometheus() {
    systemctl start prometheus
    wait_for_endpoint http://localhost:9090 302 15
}

stop_prometheus() {
    systemctl stop prometheus
}

