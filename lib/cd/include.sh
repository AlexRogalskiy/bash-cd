#!/usr/bin/env bash

APPLICABLE_SERVICES+=("cd")

start_cd() {
    #reboot -f

    #cd service restart instead of stop-start because the running server.sh gets interrupted
    restart -q cd
    start -q cd
}