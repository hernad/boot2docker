#!/bin/sh

DISK=sda
POOL=green

. /etc/green_common

if ( ! is_vbox )
then
   log_msg "automatsko kreiranje zpool-a: mora biti vbox"
   exit 1
fi

fdisk_exist () {
fdisk -l /dev/${DISK} | grep -q "/dev/$1"
}

echo "${GREEN}vbox create pool.sh start${NORMAL}"
if ( zpool list | grep -q $POOL )
then
  echo "zpool green already exists"
  exit 0
fi

vbox_extract_userdata_tar  # extract before initializing disk with zpool

fdisk -l /dev/$DISK >> $LOG_FILE

if ( ! fdisk_exist ${DISK}1 )
then
  #log_msg "vbox zpool fdisk create $DISK partition 1"
  #n p 1 1 <enter> w
  #(echo n; echo p; echo 1; echo 1; echo ; echo w) | fdisk /dev/${DISK}
  log_msg "zpool create $POOL na /dev/${DISK}"
  zpool create -o ashift=12 -f $POOL /dev/${DISK}
  zpool list >> $LOG_FILE
else
  log_msg "${DISK} partition 1 already exists"
  exit 1
fi
