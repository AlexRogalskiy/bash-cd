#!/usr/bin/env bash

cd /opt/bash-cd-source

source lib/tools.sh

continue $? "could not locate /opt/bash-cd-source"

git add . && git commit -m "$(date)"

git push
continue $? "could commit changes "

