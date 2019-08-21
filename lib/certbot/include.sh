#!/usr/bin/env bash

apply "certbot"

setup_certbot() {
  if [ -z $(command -v certbot) ]; then
    cat <<EOF | sudo tee /etc/apt/sources.list.d/stretch-backports.list
deb http://http.debian.net/debian stretch-backports main contrib non-free
EOF
    deb http://http.debian.net/debian stretch-backports main
    apt-get update -y
    apt-get install --allow-unauthenticated -y certbot -t stretch-backports
  fi
}
