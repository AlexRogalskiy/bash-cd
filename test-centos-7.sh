#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

C="bash-cd-centos"
if [ -z $(docker ps -aq -f name=$C) ]; then
    docker run  -d --rm -e=container=docker --tmpfs /run --tmpfs /run/lock --tmpfs /tmp -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                -v $DIR/env:/opt/bash-cd/env \
                -v $DIR/lib:/opt/bash-cd/lib \
                -p 9418:9418 \
                -p 8082:8081 \
                -p 29091:29091 \
                -p 9091:9091 \
                -p 9090:9090 \
                -p 8881:8881 \
                -p 3000:3000 \
                -p 8400:8400 \
                --name $C centos:7 /sbin/init
fi


docker cp $DIR/apply.sh $C:/opt/bash-cd/
docker exec -it $C /bin/bash -c "cd /opt/bash-cd && /bin/bash"

