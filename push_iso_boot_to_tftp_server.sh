#!/bin/sh

GREENBOX_VERSION=`cat GREENBOX_VERSION`
ROOT_SRV=root@192.168.168.117
TFTP_DIR=/srv/tftp
TFTP_DEST=$ROOT_SRV:$TFTP_DIR
rm greenbox.iso

echo "greenbox version: $GREENBOX_VERSION"


docker run --rm greenbox:$GREENBOX_VERSION > greenbox.iso

[ -f greenbox.iso ] && echo greenbox.iso created
[ ! -f greenbox.iso  ] && echo ERROR greenbox.iso NOT created


hdiutil mount -mountpoint /Volumes/greenbox greenbox.iso

ssh  $ROOT_SRV "mkdir -p $TFTP_DIR/boot-$GREENBOX_VERSION"
scp -r /Volumes/greenbox/boot/* $TFTP_DEST/boot-$GREENBOX_VERSION
ssh  $ROOT_SRV "ls -l $TFTP_DIR/boot ; rm $TFTP_DIR/boot"
ssh  $ROOT_SRV "ln -s  $TFTP_DIR/boot-$GREENBOX_VERSION $TFTP_DIR/boot ; ls -l $TFTP_DIR/boot"

hdiutil unmount /Volumes/greenbox
