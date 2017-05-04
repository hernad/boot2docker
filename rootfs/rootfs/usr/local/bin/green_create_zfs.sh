#!/bin/sh

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


POOL=green



if ( ! zpool list $POOL )
then
   log_msg "zpool $POOL doesn't exists"
fi

if zfs_up && ( ! mountedOnGreen opt_boot )
then
    mkdir -p $BOOT_DIR
    rm -r -f $BOOT_DIR/*
fi

log_msg "zfs opt_boot, opt_apps"
( zfs list $POOL/opt_boot ) || ( zfs create -o mountpoint=$BOOT_DIR green/opt_boot )
( zfs list $POOL/opt_apps ) || ( zfs create -o mountpoint=/opt/apps green/opt_apps )

log_msg "zfs docker_home"
( zfs list $POOL/docker_home) || \
   ( zfs create -o mountpoint=/home/docker -o quota=$HOME_QUOTA green/docker_home )


log_msg "zfs build"
( zfs list $POOL/build )      || ( zfs create -o mountpoint=/build -o quota=$BUILD_QUOTA green/build )

if ( is_vbox )
then
  # vbox host, zfs storage
  zfs create green/docker
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
   mkswap  /dev/zvol/$POOL/swap
   swapon /dev/zvol/$POOL/swap
fi

[ -d $BOOT_DIR/etc ] || mkdir -p $BOOT_DIR/etc
[ -d $BOOT_DIR/log ] || mkdir -p $BOOT_DIR/log
[ -d $BOOT_DIR/zfs ] || mkdir -p $BOOT_DIR/zfs

ln -s $BOOT_DIR/zfs /etc/zfs

zpool set cachefile=/etc/zfs/zpool.cache green
