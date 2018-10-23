#!/usr/bin/env bash

#test
kafka-topics --create --if-not-exists --topic test --partitions 4 --replication-factor $$KAFKA_REPL_FACTOR

#kafka-metrics
kafka-topics --create --if-not-exists --topic _metrics --partitions 7 --replication-factor $$KAFKA_REPL_FACTOR
kafka-topics --alter --topic _metrics --config retention.ms=345600000 #96 hours
