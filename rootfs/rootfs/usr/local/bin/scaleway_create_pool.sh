#!/bin/sh

SCALEWAY_SIGNAL_SERVER="169.254.42.42"
DISK=vda
POOL=green

. /etc/green_common

echo "${GREEN}scaleway create pool.sh start${NORMAL}"


if ( ! scaleway_server )
then
   log_msg "automatsko kreiranje zpool-a: scaleway only"
   exit 1
fi

if ( zpool list | grep -q $POOL )
then
  echo "zpool green already exists"
  exit 0
fi

fdisk /dev/vda -l | grep GB >> $LOG_FILE

zpool create -f $POOL /dev/${DISK}
zpool list >> $LOG_FILE
