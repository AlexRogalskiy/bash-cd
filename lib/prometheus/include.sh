#!/usr/bin/env bash

checkvar PROMETHEUS_SERVERS
checkvar PROMETHEUS_DATA_DIR
checkvar PROMETHEUS_RETENTION

for i in "${!PROMETHEUS_SERVERS[@]}"
do
   if [ "${PROMETHEUS_SERVERS[$i]}" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("prometheus")
    export PROMETHEUS_URL="http://localhost:9090"
    if [ ! -z "$KAFKA_SERVERS" ]; then
        export KAFKA_PROMETHEUS_TARGETS
        export PROMETHEUS_DATA_DIR
        export PROMETHEUS_RETENTION
        for i in "${!KAFKA_SERVERS[@]}"
        do
           kafka_host="${KAFKA_ADVERTISED_HOSTS[$i]}"
           KAFKA_PROMETHEUS_TARGETS="${KAFKA_PROMETHEUS_TARGETS} ${kafka_host}:7071,"
        done
    fi
   fi
done

build_prometheus() {
    VERSION=2.4.3
    DOWNLOAD="prometheus-$VERSION.linux-amd64"
    download "https://github.com/prometheus/prometheus/releases/download/v$VERSION/$DOWNLOAD.tar.gz" $BUILD_DIR/opt/
    continue $? "failed to download prometheus"
}

install_prometheus() {
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

    id -u prometheus > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        useradd --no-create-home --shell /bin/false prometheus
        useradd --no-create-home --shell /bin/false node_exporter
    fi
    mkdir -p $PROMETHEUS_DATA_DIR
    chown -R prometheus:prometheus $PROMETHEUS_DATA_DIR
    continue $? "failed to create prometheus user"
    chown prometheus:prometheus /opt/prometheus/prometheus
    chown prometheus:prometheus /opt/prometheus/promtool
    cp -r /opt/prometheus/consoles /etc/prometheus
    cp -r /opt/prometheus/console_libraries /etc/prometheus
    chown -R prometheus:prometheus /etc/prometheus
    systemctl daemon-reload
    systemctl enable prometheus
}

start_prometheus() {
    systemctl start prometheus
    wait_for_endpoint http://localhost:9090 302 15
}

stop_prometheus() {
    systemctl stop prometheus
}

