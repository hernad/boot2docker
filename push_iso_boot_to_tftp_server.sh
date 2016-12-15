#!/bin/sh

GREENBOX_VERSION=`cat GREENBOX_VERSION`
ROOT_SRV=root@192.168.168.117
TFTP_DIR=/srv/tftp
TFTP_DEST=$ROOT_SRV:$TFTP_DIR
rm greenbox.iso

echo "greenbox version: $GREENBOX_VERSION"

if uname -a | grep -q Linux
then
	LINUX=1
else
        LINUX=0
fi


echo creating greenbox.iso ...
docker run --rm greenbox:$GREENBOX_VERSION > greenbox.iso

[ -f greenbox.iso ] && echo greenbox.iso created
[ ! -f greenbox.iso  ] && echo ERROR greenbox.iso NOT created

if [ "$LINUX" == "1" ] ; then
	MNT_DIR=/mnt/greenbox
	#sudo mkdir -p /mnt/greenbox
        echo mount linux $MNT_DIR
	sudo mount -o loop greenbox.iso $MNT_DIR
else
	MNT_DIR=/Volumes/greenbox
	echo mount macOS $MNT_DIR
	hdiutil mount -mountpoint $MNT_DIR greenbox.iso
fi

ssh  $ROOT_SRV "mkdir -p $TFTP_DIR/boot-$GREENBOX_VERSION"
scp -r $MNT_DIR/boot/* $TFTP_DEST/boot-$GREENBOX_VERSION
ssh  $ROOT_SRV "ls -l $TFTP_DIR/boot ; rm $TFTP_DIR/boot"
ssh  $ROOT_SRV "ln -s  $TFTP_DIR/boot-$GREENBOX_VERSION $TFTP_DIR/boot ; ls -l $TFTP_DIR/boot* ; ls -l $TFTP_DIR/boot/*"

echo umount
if [ "$LINUX" == 1 ]
then
	sudo umount $MNT_DIR
else
	hdiutil unmount /Volumes/greenbox
fi
