#!/bin/sh

DOCKER_VERSION=`cat DOCKER_VERSION`

rm greenbox.iso

docker run --rm greenbox:$DOCKER_VERSION > greenbox.iso

[ -f greenbox.iso ] && echo greenbox.iso created
[ ! -f greenbox.iso  ] && echo ERROR greenbox.iso NOT created
