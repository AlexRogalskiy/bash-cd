#!/usr/bin/env bash

docker run -d --name gogs -p 8022:22 -p 3000:3000  gogs/gogs:latest

