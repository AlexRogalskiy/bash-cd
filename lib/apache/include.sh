#!/usr/bin/env bash

checkvar WEB_SERVER

if [ "$WEB_SERVER" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("apache")
fi

setup_apache() {
    sudo apt-get -y install apache2
    a2enmod ssl
    a2enmod proxy
    a2enmod proxy_http
    a2enmod proxy_wstunnel
    a2enmod proxy_balancer
    a2enmod lbmethod_byrequests
}

build_apache() {
    mkdir -p $BUILD_DIR/etc/apache2/sites-enabled
    ln -sfn $BUILD_DIR/etc/apache2/sites-available/default.conf $BUILD_DIR/etc/apache2/sites-enabled/
}

start_apache() {
    systemctl start apache2
}

stop_apache() {
    systemctl stop apache2.service
}

