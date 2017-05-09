#!/bin/sh

DISK=vda
POOL=green

. /etc/green_common
. /etc/init.d/tc-functions

set_path_ld_library

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
