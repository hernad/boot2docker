#!/bin/sh

DOCKER_VERSION=`cat DOCKER_VERSION`

docker run --rm greenbox:$DOCKER_VERSION > greenbox.iso

echo greenbox.iso created
