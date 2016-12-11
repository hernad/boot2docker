#!/bin/sh

DISK=sda
POOL=green

. /etc/green_common

fdisk_exist () {
fdisk -l /dev/${DISK} | grep -q "/dev/$1"
}

if ( ! is_vbox )
then
   log_msg "automatsko kreiranje zpool-a: mora biti vbox"
   exit 1
fi

if ( zpool list | grep -q $POOL )
then
  echo "zpool green already exists"
  exit 0
fi


fdisk -l /dev/$DISK >> $LOG_FILE

if ( ! fdisk_exist ${DISK}1 )
then
  log_msg "create $DISK partition 1"
  #n p 1 1 <enter> w
  (echo n; echo p; echo 1; echo 1; echo ; echo w) | sudo fdisk /dev/${DISK}
  log_msg "zpool create $POOL na /dev/${DISK}1"
  zpool create -f $POOL /dev/${DISK}1
  zpool list >> $LOG_FILE
else
  log_msg "${DISK} partition 1 already exists"
  exit 1
fi
