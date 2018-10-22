#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

C="bash-cd-ubuntu"
if [ ! $(docker inspect -f {{.State.Running}} $C) ]; then
    docker run  -d --privileged=true \
                -v $DIR/env:/opt/bash-cd/env \
                -v $DIR/lib:/opt/bash-cd/lib \
                -p 8082:8082 \
                -p 9092:9092 \
                -p 8881:8881 \
                --name $C ubuntu:16.04 /sbin/init
fi

docker cp $DIR/apply.sh /opt/bash-cd/

docker exec -it $C /bin/bash -c "cd /opt/bash-cd && /bin/bash"

