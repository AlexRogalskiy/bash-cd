#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

C="bash-cd-ubuntu-git"
if [ -z "$(docker ps -aq -f name=$C)" ]; then
    docker run  --rm -d --privileged=true \
                -v $DIR/env:/opt/bash-cd/env \
                -v $DIR/lib:/opt/bash-cd/lib \
                -p 9418:9418 \
                --name $C ubuntu:16.04 /sbin/init
fi

docker cp $DIR/apply.sh $C:/opt/bash-cd/
docker exec -it $C /bin/bash -c "cd /opt/bash-cd && ./apply.sh --host HOST0"

