#!/bin/sh

. /etc/green_common

zfs_partition_sda_exists() {
   /sbin/fdisk $DISK -l | grep -q 0700
}

mount_green_btrfs() {
 log_msg "mounting btrfs /green-btrfs on disk $DISK" Y
 mkdir -p /green-btrfs
 # btrfs device scan is used to scan all of the block devices under /dev and probe for Btrfs volumes. This is required after loading the btrfs module if you're running with more than one device in a filesystem.
 btrfs device scan
 mount $DISK /green-btrfs
}

DISK=/dev/sda

if ( ! is_vbox )
then
   mount_green_btrfs
   exit 0
fi


if zfs_partition_sda_exists
then
  log_msg "zfs partition on $DISK - STOP"
  exit 1
fi

vbox_extract_userdata_tar  # extract before initializing disk with btrfs

#fdisk -l /dev/$DISK >> $LOG_FILE
if btrfs inspect-internal dump-super ${DISK} | grep -q num_devices
then
  echo "${DISK} btrfs signature already exists"
else
  mkfs.btrfs -f -L "green-btrfs" $DISK
fi

btrfs inspect-internal dump-super ${DISK}  >> $LOG_FILE

mount_green_btrfs
