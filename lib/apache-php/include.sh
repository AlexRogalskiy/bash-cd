#!/usr/bin/env bash

checkvar WEB_SERVER

if [ "$WEB_SERVER" == "$PRIMARY_IP" ]; then
    apply "apache"
    apply "apache-php"
fi

setup_apache-php() {
    apt-get -y install libapache2-mod-php
    apt-get install php-gd
    apt-get install php-curl
    apt-get install libssh2-php
    apt-get install php-ssh2
}


