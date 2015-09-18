#!/bin/sh


DOCKER_VERSION=`cat DOCKER_VERSION`

docker rmi greenbox:$DOCKER_VERSION
docker build -t greenbox:$DOCKER_VERSION .
