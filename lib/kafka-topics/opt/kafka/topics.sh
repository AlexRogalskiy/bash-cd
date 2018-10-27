#!/usr/bin/env bash

#test
kafka-topics --create --if-not-exists --topic test --partitions 4 --replication-factor $$KAFKA_REPL_FACTOR
kafka-topics --create --if-not-exists --topic test-copy --partitions 4 --replication-factor $$KAFKA_REPL_FACTOR
