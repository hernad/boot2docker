#!/bin/sh

DISK=sda
POOL=green

. /etc/green_common

fdisk_exist () {

fdisk -l /dev/${DISK} | grep -q "/dev/$1"

}

if ( ! is_vbox )
then
   echo "mora biti vbox" 
   exit 1
fi

if ( zpool list | grep -q $POOL )
then
  echo "zpool green vec postoji"
  exit 0
fi


fdisk -l /dev/$DISK >> $LOG_FILE

if ( ! fdisk_exist ${DISK}1 )
then
  echo create $DISK partition 1
  #n p 1 1 <enter> w
  (echo n; echo p; echo 1; echo 1; echo ; echo w) | sudo fdisk /dev/${DISK}
else
  echo ${DISK} partition 1 exists
  exit 1
fi

if ( fdisk_exist ${DISK}1 ) 
then
   echo kreiram zpool $POOL na /dev/${DISK}1
   zpool create -f $POOL /dev/${DISK}1
else
   echo "${DISK} partition 1 doesn't exists"
fi

zpool list >> $LOG_FILE

