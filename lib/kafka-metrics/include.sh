#!/usr/bin/env bash

checkvar KAFKA_VERSION

APPLICABLE_SERVICES+=("kafka-metrics")

KV="${KAFKA_VERSION:0:3}"
if [ "$KV" == "2.0" ]; then
    KM_BRANCH="master";
else
    KM_BRANCH="master-$KV"
fi
export KAFKA_METRICS_HOME="/opt/kafka-metrics-$KM_BRANCH"

function build_kafka-metrics() {
#    if [[ $KM_BRANCH == master* ]]; then
#        rm -r $KAFKA_METRICS_HOME
#    fi
    mkdir -p $KAFKA_METRICS_HOME
    download https://github.com/amient/kafka-metrics/archive/$KM_BRANCH.zip $KAFKA_METRICS_HOME
    cd $KAFKA_METRICS_HOME
    if [ ! -d src ]; then
        unzip $KM_BRANCH.zip -d ../
        continue $? "Failed to unzip kafka-metrics archive"
        cd $KAFKA_METRICS_HOME
    fi
}
