#!/usr/bin/env bash

#Schema Registry
#kafka-acls --add --allow-principal 'User:schemas' --topic _schemas --consumer --group '*'
#kafka-acls --add --allow-principal 'User:schemas' --topic _schemas --producer --group '*'
#kafka-acls --add --allow-principal 'User:schemas' --topic _schemas --operation DescribeConfigs
#kafka-acls --add --allow-principal 'User:schemas' --topic __consumer_offsets --operation Describe

#Mirror Producers
#kafka-acls --add --allow-principal 'User:mirror' --producer --topic '*' --group '*'
