#!/bin/sh

DISK=vda
POOL=green

. /etc/green_common

if ( ! scaleway_server ) && ( ! vultr_server )
then
   log_msg "automatsko kreiranje zpool-a: za cloud servere only"
   exit 1
fi

if ( zpool list | grep -q $POOL )
then
  echo "zpool green already exists"
  exit 0
fi

echo "${GREEN}cloud vda create pool.sh start${NORMAL}"
fdisk /dev/vda -l | grep GB >> $LOG_FILE

zpool create -f $POOL /dev/${DISK}
zpool list >> $LOG_FILE
