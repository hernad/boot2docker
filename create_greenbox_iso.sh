#!/bin/sh

GREENBOX_VERSION=`cat GREENBOX_VERSION`

rm greenbox.iso

echo "greenbox version: $GREENBOX_VERSION"


docker run --rm greenbox:$GREENBOX_VERSION > greenbox.iso

[ -f greenbox.iso ] && echo greenbox.iso created
[ ! -f greenbox.iso  ] && echo ERROR greenbox.iso NOT created


[ -d vbox ] && cp greenbox.iso vbox/ && echo "copied to vbox/"
