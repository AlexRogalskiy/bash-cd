#!/usr/bin/env bash

APPLICABLE_SERVICES+=("cd")

start_cd() {
    #cd service restart instead of stop-start because the running /opt/bash-cd-server.sh gets interrupted
    restart -q cd
    start -q cd
}