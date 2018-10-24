#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

C="bash-cd-ubuntu$1"
if [ -z $(docker ps -aq -f name=$C) ]; then
    docker run  --rm -d --privileged=true \
                -v $DIR/env:/opt/bash-cd/env \
                -v $DIR/lib:/opt/bash-cd/lib \
                -p 8082:8082 \
                -p 9092:9092 \
                -p 29092:29092 \
                -p 8881:8881 \
                -p 9090:9090 \
                -p 3000:3000 \
                --name $C ubuntu:16.04 /sbin/init
fi

docker cp $DIR/apply.sh $C:/opt/bash-cd/
docker exec -it $C /bin/bash -c "cd /opt/bash-cd && /bin/bash"

