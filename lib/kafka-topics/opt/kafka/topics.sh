#!/usr/bin/env bash

kafka-topics --create --if-not-exists --topic test --partitions 4 --replication-factor $$KAFKA_REPL_FACTOR
