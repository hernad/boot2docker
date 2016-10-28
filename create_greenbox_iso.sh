#!/bin/sh

DOCKER_VERSION=`cat DOCKER_VERSION`

rm greenbox.iso

echo $DOCKER_VERSION

docker run --rm greenbox:$DOCKER_VERSION > greenbox.iso

[ -f greenbox.iso ] && echo greenbox.iso created
[ ! -f greenbox.iso  ] && echo ERROR greenbox.iso NOT created


[ -d vbox ] && cp greenbox.iso vbox/ && echo "copied to vbox/"
