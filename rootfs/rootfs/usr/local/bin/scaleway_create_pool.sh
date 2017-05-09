#!/bin/sh

SCALEWAY_SIGNAL_SERVER="169.254.42.42"
DISK=vda
POOL=green

. /etc/green_common

scaleway_server () {

#parted /dev/vda  print
#WARNING: You are not superuser.  Watch out for permissions.
#Model: Virtio Block Device (virtblk)
#Disk /dev/vda: 50.0GB

parted /dev/vda print | grep -q "/dev/$1.*GB"
if [ "$?" != "0" ]; then
   return 1
fi

#initrd=initrd showopts console=ttyS0,115200 nousb vga=0 root=/dev/vda ip=:::::eth0: boot=local
cat /proc/cmdline | grep -q "root=/dev/vda"
if [ "$?" != "0" ]; then
   return 1
fi


[ -d /run ] || mkdir /run
curl http://$SCALEWAY_SIGNAL_SERVER/conf -X GET > /run/scw-metadata.cache
cat /run/scw-metadata.cache  | grep PUBLIC_IP_ADDRESS

}

if ( ! scaleway_server )
then
   log_msg "automatsko kreiranje zpool-a: mora biti scaleway"
   exit 1
fi

if ( zpool list | grep -q $POOL )
then
  echo "zpool green already exists"
  exit 0
fi


parted /dev/$DISK print >> $LOG_FILE

zpool create -f $POOL /dev/${DISK}
zpool list >> $LOG_FILE
