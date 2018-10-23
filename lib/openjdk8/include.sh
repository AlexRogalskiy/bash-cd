#!/usr/bin/env bash

APPLICABLE_SERVICES+=("openjdk8")

setup_openjdk8() {
    yum -y install java-1.8.0-openjdk
}
