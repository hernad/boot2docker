#!/bin/sh

TFTP_SERVER=${TFTP_SERVER:-192.168.168.117}

SSH_OPT=""
if [ -f .ssh_download_key ] ; then
  SSH_OPT="-i .ssh_download_key"
  chmod 0600 .ssh_download_key
fi

if [ -f id_rsa ] ; then
  SSH_OPT="-i id_rsa"
  chmod 0600 id_rsa
fi


GREENBOX_VERSION=`cat GREENBOX_VERSION`
ROOT_SRV=root@$TFTP_SERVER
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
        [ -d /mnt/greenbox ]  || sudo mkdir -p /mnt/greenbox
        echo mount linux $MNT_DIR
	sudo mount -o loop greenbox.iso $MNT_DIR
else
	MNT_DIR=/Volumes/greenbox
	echo mount macOS $MNT_DIR
	hdiutil mount -mountpoint $MNT_DIR greenbox.iso
fi

ssh $SSH_OPT  $ROOT_SRV "mkdir -p $TFTP_DIR/boot-$GREENBOX_VERSION"
scp $SSH_OPT -r $MNT_DIR/boot/* $TFTP_DEST/boot-$GREENBOX_VERSION
ssh $SSH_OPT $ROOT_SRV "ls -l $TFTP_DIR/boot ; rm $TFTP_DIR/boot"
ssh $SSH_OPT $ROOT_SRV "ln -s  $TFTP_DIR/boot-$GREENBOX_VERSION $TFTP_DIR/boot ; ls -l $TFTP_DIR/boot* ; ls -l $TFTP_DIR/boot/*"

echo umount
if [ "$LINUX" == 1 ]
then
	sudo umount $MNT_DIR
else
	hdiutil unmount /Volumes/greenbox
fi
