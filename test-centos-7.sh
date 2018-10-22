#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

C="bash-cd-centos"
if [ ! $(docker inspect -f {{.State.Running}} $C) ]; then
    docker run  -e=container=docker  \
                -d --rm --tmpfs /run --tmpfs /run/lock --tmpfs /tmp \
                -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                -v $DIR/env:/opt/bash-cd/env \
                -v $DIR/lib:/opt/bash-cd/lib \
                -p 8082:8082 \
                -p 9092:9092 \
                -p 8881:8881 \
                --name $C centos:7 /sbin/init
fi

docker cp $DIR/apply.sh $C:/opt/bash-cd/
docker exec -it $C /bin/bash -c "cd /opt/bash-cd && ./apply.sh setup && /bin/bash"

