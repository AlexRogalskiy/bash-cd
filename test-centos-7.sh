#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

C="bash-cd-centos"
if [ -z $(docker ps -aq -f name=$C) ]; then
    docker run  -e=container=docker  \
                -d --rm --tmpfs /run --tmpfs /run/lock --tmpfs /tmp \
                -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                -v $DIR/env:/opt/bash-cd/env \
                -v $DIR/lib:/opt/bash-cd/lib \
                -p 18082:8082 \
                -p 19092:9092 \
                -p 18881:8881 \
                -p 18086:8086 \
                -p 19090:9090 \
                -p 13000:3000 \
                --name $C centos:7 /sbin/init

docker cp $DIR/apply.sh $C:/opt/bash-cd/
docker exec -it $C /bin/bash -c "cd /opt/bash-cd && /bin/bash"

