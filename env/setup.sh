#!/usr/bin/env bash

# CHANGES TO THIS FILE ARE MONITORED. IF CHANGE IS DETECTED
# THE SCRIPT WILL BE EXECUTED ON THE HOST BEFORE APPLYING A COMPLETE RE-INSTALLATION OF ALL SERVICES
#####################################################################################################################

EPOCH=1   # epoch is a dummy variable that simply changes the checksum of this file and thus triggering this script

#####################################################################################################################

update-ca-certificates -f

wget -qO - https://packages.confluent.io/deb/4.0/archive.key | sudo apt-key add -
add-apt-repository -y "deb [arch=amd64] https://packages.confluent.io/deb/4.0 stable main"
add-apt-repository -y ppa:openjdk-r/ppa
apt-get -y update

apt-get install upstart #apt-get -y install upstart-sysv

update-initramfs -u
apt-get -y purge systemd
apt-get -y install openjdk-8-jdk

apt-get -y install ntp

apt-get -y autoremove
