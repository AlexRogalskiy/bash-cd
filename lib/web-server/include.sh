#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar WEB_SERVER

if [ "$WEB_SERVER" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("web-server")
fi

setup_web-server() {
    sudo apt-get -y install apache2
    apt-get -y install libapache2-mod-php
    apt-get install php-gd
    apt-get install php-curl
    apt-get install libssh2-php
    apt-get install php-ssh2
    a2enmod ssl
    a2enmod proxy
    a2enmod proxy_http
    a2enmod proxy_wstunnel
    a2enmod proxy_balancer
    a2enmod lbmethod_byrequests
}

build_web-server() {
    mkdir -p $BUILD_DIR/etc/apache2/sites-enabled
    ln -sfn $BUILD_DIR/etc/apache2/sites-available/default.conf $BUILD_DIR/etc/apache2/sites-enabled/
}

start_web-server() {
    #start -q apache2
    systemctl start apache2
}

stop_web-server() {
    #stop -q apache2
    systemctl stop apache2.service
}

