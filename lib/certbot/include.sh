#!/usr/bin/env bash

APPLICABLE_SERVICES+=("certbot")

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

#install_certbot() {
#    systemctl daemon-reload
#    systemctl enable cd.service
#}

#cd service restart instead of stop-start because the running /opt/bash-cd-server.sh gets interrupted
#start_cd() {
#    systemctl restart cd.service || systemctl start cd.service
#    systemctl start ssh
#}
