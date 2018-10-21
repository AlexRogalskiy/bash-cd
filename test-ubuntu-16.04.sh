#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker run  -d --privileged=true \
            -v $DIR/env:/opt/bash-cd/env \
            -v $DIR/lib:/opt/bash-cd/lib \
            -v $DIR/apply.sh:/opt/bash-cd/apply.sh \
            -p 8082:8082 \
            -p 9092:9092 \
            -p 8881:8881 \
            --name bash-cd-ubuntu ubuntu:16.04 /sbin/init

docker exec -it bash-cd-ubuntu /bin/bash -c "cd /opt/bash-cd && /bin/bash"

