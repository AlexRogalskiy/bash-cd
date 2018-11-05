#!/usr/bin/env bash

#Admin
kafka-acls --add --allow-principal 'User:admin' --producer --topic '*' --group '*'
kafka-acls --add --allow-principal 'User:admin' --topic '*' --operation DescribeConfigs
kafka-acls --add --allow-principal 'User:admin' --topic '*' --operation Describe

#Schema Registry
kafka-acls --add --allow-principal 'User:schemaregistry' --topic _schemas --consumer --group '*'
kafka-acls --add --allow-principal 'User:schemaregistry' --topic _schemas --producer --group '*'
kafka-acls --add --allow-principal 'User:schemaregistry' --topic _schemas --operation DescribeConfigs
kafka-acls --add --allow-principal 'User:schemaregistry' --topic __consumer_offsets --operation Describe

