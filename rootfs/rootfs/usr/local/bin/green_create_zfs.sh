#!/bin/bash

. /etc/green_common

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

if [ -n "$MEMKB" ] ; then
  if [ $MEMKB -ge 2000000 ]; then
      SWAP_VOL_SIZE=4G
  fi
  if [ $MEMKB -ge 4000000 ]; then
      SWAP_VOL_SIZE=8G
  fi
  if [ $MEMKB -ge 8000000 ]; then
      SWAP_VOL_SIZE=16G
  fi
  if [ $MEMKB -ge 16000000 ]; then
      SWAP_VOL_SIZE=32G
  fi
  if [ $MEMKB -ge 32000000 ]; then
      SWAP_VOL_SIZE=48G
  fi
  if [ $MEMKB -ge 64000000 ]; then
      SWAP_VOL_SIZE=96G
  fi
fi

POOL=green

if ( ! zpool list $POOL )
then
   log_msg "zpool $POOL doesn't exists" R
   exit 1
fi

ZFS_VOL=opt_boot
MOUNT_DIR=$BOOT_DIR
if [ -n "$MOUNT_DIR" ] && zfs_up && ( ! mountedOnGreen $ZFS_VOL ) ; then
   if ! volumeExistsOnGreen $ZFS_VOL ; then
     #rm -r -f $MOUNT_DIR
     #mkdir -p $MOUNT_DIR
     zfs create -o mountpoint=$MOUNT_DIR green/$ZFS_VOL
     if [ $? == 0 ] ; then
       log_msg "zfs create $POOL/$ZFS_VOL ; mounted on $MOUNT_DIR up :)" G
     else
        log_msg "zfs create $POOL/$ZFS_VOL ; mounted on $MOUNT_DIR DOWN :(" R
     fi
   else
      zfs mount green/$ZFS_VOL
      if [ $? != 0 ] ;then log_msg "zfs mount green/$ZFS_VOL ERROR" R ;else log_msg "zfs mount green/$ZFS_VOL OK" G ; fi
   fi
fi

ZFS_VOL=opt_apps
MOUNT_DIR=/opt/apps
if [ -n "$MOUNT_DIR" ] && zfs_up && ( ! mountedOnGreen $ZFS_VOL ) ; then
   #rm -r -f $MOUNT_DIR
   #mkdir -p $MOUNT_DIR
   if ! volumeExistsOnGreen $ZFS_VOL ; then
     zfs create -o mountpoint=$MOUNT_DIR green/$ZFS_VOL
     if [ $? == 0 ] ; then
       log_msg "zfs create $POOL/$ZFS_VOL ; mounted on $MOUNT_DIR up :)" G
     else
       log_msg "zfs create $POOL/$ZFS_VOL ; mounted on $MOUNT_DIR DOWN :(" R
     fi
   else
      zfs mount green/$ZFS_VOL
      if [ $? != 0 ] ;then log_msg "zfs mount green/$ZFS_VOL ERROR" R ;else log_msg "zfs mount green/$ZFS_VOL OK" G ; fi
   fi
fi

ZFS_VOL=docker_home
MOUNT_DIR=${DOCKER_HOME_DIR}
if [ -n "$MOUNT_DIR" ] && zfs_up && ( ! mountedOnGreen $ZFS_VOL ) ; then
   #rm -r -f $MOUNT_DIR
   #mkdir -p $MOUNT_DIR
   if ! volumeExistsOnGreen $ZFS_VOL ; then
      zfs create -o quota=$HOME_QUOTA -o mountpoint=$MOUNT_DIR green/$ZFS_VOL
      if [ $? == 0 ] ; then
         log_msg "zfs create $POOL/$ZFS_VOL ; mounted on $MOUNT_DIR up :)" G
      else
        log_msg "zfs create $POOL/$ZFS_VOL ; mounted on $MOUNT_DIR DOWN :(" R
      fi
    else
      zfs mount green/$ZFS_VOL
      if [ $? != 0 ] ;then log_msg "zfs mount green/$ZFS_VOL ERROR" R ;else log_msg "zfs mount green/$ZFS_VOL OK" G ; fi
    fi
fi

ZFS_VOL=build
MOUNT_DIR=/build
if [ -n "$MOUNT_DIR" ] && zfs_up && ( ! mountedOnGreen $ZFS_VOL ) ; then
  #rm -r -f $MOUNT_DIR
  #mkdir -p $MOUNT_DIR
  if ! volumeExistsOnGreen $ZFS_VOL ; then
    zfs create -o mountpoint=$MOUNT_DIR green/$ZFS_VOL
    if [ $? == 0 ] ; then
       log_msg "zfs create $POOL/$ZFS_VOL ; mounted on $MOUNT_DIR up :)" G
    else
       log_msg "zfs create $POOL/$ZFS_VOL ; mounted on $MOUNT_DIR DOWN :(" R
    fi
  else
    zfs mount green/$ZFS_VOL
    if [ $? != 0 ] ;then log_msg "zfs mount green/$ZFS_VOL ERROR" R ;else log_msg "zfs mount green/$ZFS_VOL OK" G ; fi
  fi
fi

if ( is_vbox )
then
  zfs create green/docker # vbox host, zfs storage
else
  # NOT vbox host, overlay2 storage
  if ( ! zfs list $POOL/docker_vol )
  then
     log_msg "zfs docker_vol /dev/zvol"
     zfs create -V $DOCKER_VOL_SIZE -s -o sync=disabled $POOL/docker_vol
     wait_zvol_up $POOL docker_vol
     log_msg "docker_vol mkfs.ext4"
     mkfs.ext4 -F /dev/zvol/$POOL/docker_vol

     log_msg "mount docker_vol /var/lib/docker"
     mkdir -p /var/lib/docker
     mount /dev/zvol/$POOL/docker_vol /var/lib/docker
  fi
fi

if ( ! zfs list $POOL/swap )
then
   log_msg "zfs create swap /dev/zvol"
   zfs create  -V $SWAP_VOL_SIZE \
      -b $(getconf PAGESIZE) -o primarycache=metadata -o com.sun:auto-snapshot=false -o sync=disabled -s $POOL/swap
   wait_zvol_up $POOL swap

   cat /proc/swaps | grep zd
   mkswap  /dev/zvol/$POOL/swap
   swapon /dev/zvol/$POOL/swap
fi

[ -d $BOOT_DIR/etc ] || mkdir -p $BOOT_DIR/etc
[ -d $BOOT_DIR/log ] || mkdir -p $BOOT_DIR/log
[ -d $BOOT_DIR/zfs ] || mkdir -p $BOOT_DIR/zfs

[ -e /etc/zfs ] || ln -s $BOOT_DIR/zfs /etc/zfs

[ -f /etc/zfs/zpool.cache ] || zpool set cachefile=/etc/zfs/zpool.cache green
