#!/usr/bin/env bash

checkvar WEB_SERVER

if [ "$WEB_SERVER" == "$PRIMARY_IP" ]; then
    APPLICABLE_MODULES+=("nginx")
fi

setup_nginx() {
    apt-get -y -o Dpkg::Options::=--force-confdef install nginx
}

install_nginx() {
    mkdir -p /data/log/nginx
    chown -R www-data:www-data /data/log/nginx
}

start_nginx() {
    systemctl start nginx
}

stop_nginx() {
    systemctl stop nginx
}

