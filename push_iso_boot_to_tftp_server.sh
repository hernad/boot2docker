#!/bin/sh

GREENBOX_VERSION=`cat GREENBOX_VERSION`
TFTP_DEST=root@192.168.168.117:/srv/tftp/
rm greenbox.iso

echo "greenbox version: $GREENBOX_VERSION"


docker run --rm greenbox:$GREENBOX_VERSION > greenbox.iso

[ -f greenbox.iso ] && echo greenbox.iso created
[ ! -f greenbox.iso  ] && echo ERROR greenbox.iso NOT created


hdiutil mount -mountpoint /Volumes/greenbox greenbox.iso

scp -r /Volumes/greenbox/boot $TFTP_DEST
 
hdiutil unmount /Volumes/greenbox
