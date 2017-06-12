#!/bin/bash

. /etc/green_common

zram_size() {
SIZE=$1
echo $(($SIZE*1024*1024)) > /sys/block/zram0/disksize
}

if ( is_vbox )
then
 log_msg "vbox"
 HOME_QUOTA=50G
 BUILD_QUOTA=30G
 DOCKER_VOL_SIZE=30G
 SWAP_VOL_SIZE=4G
else
 log_msg "not vbox"
 HOME_QUOTA=300G
 BUILD_QUOTA=200G
 DOCKER_VOL_SIZE=120G
 SWAP_VOL_SIZE=24G
fi

MEMKB=`cat /proc/meminfo | grep MemTotal.*kB | awk '{print $2}'`

echo "Memory in kB: $MEMKB"

# green htop 1024 RAM vbox, ZRAM_SIZE=256, 159 MB used after start
# let's try with ZRAM 512 - no difference
ZRAM_SIZE=512

if [ -n "$MEMKB" ] ; then
  if [ $MEMKB -ge 2000000 ]; then
      ZRAM_SIZE=768
  fi
  if [ $MEMKB -ge 4000000 ]; then
      ZRAM_SIZE=1024
  fi
  if [ $MEMKB -ge 8000000 ]; then
      ZRAM_SIZE=2048
  fi
  if [ $MEMKB -ge 16000000 ]; then
      ZRAM_SZE=4096
  fi
  if [ $MEMKB -ge 32000000 ]; then
      ZRAM_SIZE=8192
  fi
  if [ $MEMKB -ge 64000000 ]; then
      ZRAM_SIZE=10240
  fi
fi

zram_size $ZRAM_SIZE
mkswap /dev/zram0
swapon /dev/zram0


#btrfs filesystem show --mounted
#Label: none  uuid: d5bae635-5db6-4f92-9b00-18f378561f50
#	Total devices 1 FS bytes used 192.00KiB
#	devid    1 size 8.00GiB used 843.12MiB path /dev/sdb

#btrfs filesystem show /mnt
#Label: none  uuid: d5bae635-5db6-4f92-9b00-18f378561f50
#	Total devices 1 FS bytes used 192.00KiB
#	devid    1 size 8.00GiB used 843.12MiB path /dev/sdb

# btrfs filesystem show /mnt | grep ERROR
# ERROR: not a valid btrfs filesystem: /mnt

#btrfs filesystem show /dev/sdb
#Label: none  uuid: d5bae635-5db6-4f92-9b00-18f378561f50
#	Total devices 1 FS bytes used 192.00KiB
#	devid    1 size 8.00GiB used 843.12MiB path /dev/sdb

if ( ! btrfs filesystem show /green-btrfs )
then
   log_msg "green-btrfs does not exists!" R
   exit 1
fi

mkdir -p /green-btrfs/__snapshot
mkdir -p /green-btrfs/__current

DIR=/green-btrfs/__current/opt_boot
[  -d $DIR ] || btrfs subvolume create $DIR

DIR=/green-btrfs/__current/opt_apps
[  -d $DIR ] || btrfs subvolume create $DIR

DIR=/green-btrfs/__current/docker_home
[  -d $DIR ] || btrfs subvolume create $DIR

DIR=/green-btrfs/__current/docker
[  -d $DIR ] || btrfs subvolume create $DIR

DIR=/green-btrfs/__current/build
[  -d $DIR ] || btrfs subvolume create $DIR

DIR=/opt/boot
BTRFS_SUBVOL=__current/opt_boot
mkdir -p $DIR
mount -o $BTRFS_MOUNT_O,subvol=$BTRFS_SUBVOL $BTRFS_DEV $DIR

DIR=/opt/apps
BTRFS_SUBVOL=__current/opt_apps
mkdir -p $DIR
mount -o $BTRFS_MOUNT_O,subvol=$BTRFS_SUBVOL $BTRFS_DEV $DIR

DIR=/home/docker
BTRFS_SUBVOL=__current/docker_home
[ -f $DIR/.profile ] && rm $MOUNT_DIR/.ash* $MOUNT_DIR/.profile
mkdir -p $DIR
mount -o $BTRFS_MOUNT_O,subvol=$BTRFS_SUBVOL $BTRFS_DEV $DIR

DIR=/build
BTRFS_SUBVOL=__current/build
mkdir -p $DIR
mount -o $BTRFS_MOUNT_O,subvol=$BTRFS_SUBVOL $BTRFS_DEV $DIR

DIR=/var/lib/docker
BTRFS_SUBVOL=__current/docker
mkdir -p $DIR
mount -o $BTRFS_MOUNT_O,subvol=$BTRFS_SUBVOL $BTRFS_DEV $DIR

[ -d $BOOT_DIR/etc ] || mkdir -p $BOOT_DIR/etc
[ -d $BOOT_DIR/log ] || mkdir -p $BOOT_DIR/log
[ -d $BOOT_DIR/zfs ] || mkdir -p $BOOT_DIR/zfs
