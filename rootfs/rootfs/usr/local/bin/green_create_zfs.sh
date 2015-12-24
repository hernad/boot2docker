#!/bin/sh

. /etc/rc.d/green_common

if is_vbox
then
 HOME_QUOTA=50G
 BUILD_QUOTA=30G
 DOCKER_VOL_SIZE=30G
 SWAP_VOL_SIZE=4G
else
 HOME_QUOTA=300G
 BUILD_QUOTA=200G
 DOCKER_VOL_SIZE=120G
 SWAP_VOL_SIZE=24G
fi


POOL=green
BOOT_DIR=/opt/boot


if ( ! zpool list $POOL )
then
   log_msg "zpool $POOL doesn't exists"
fi

if zfs_up && ( ! mounted opt_boot ) 
then
    mkdir -p $BOOT_DIR 
    rm -r -f $BOOT_DIR/* 
fi

log_msg "zfs opt_boot, opt_apps"
( zfs list $POOL/opt_boot ) || ( zfs create -o mountpoint=/opt/boot green/opt_boot )
( zfs list $POOL/opt_apps ) || ( zfs create -o mountpoint=/opt/apps green/opt_apps )

log_msg "zfs docker_home"
( zfs list $POOL/docker_home) || ( zfs create -o mountpoint=/home/docker -o quota=$HOME_QUOTA green/docker_home )

log_msg "zfs build"
( zfs list $POOL/build )      || ( zfs create -o mountpoint=/build -o quota=$BUILD_QUOTA green/build )

if ( ! zfs list $POOL/docker_vol )
then
   log_msg "zfs docker_vol /dev/zvol, ext4"
   zfs create -V $DOCKER_VOL_SIZE -s -o sync=disabled $POOL/docker_vol
   mkfs.ext4 /dev/zvol/$POOL/docker_vol
fi

if ( ! zfs list $POOL/swap )
then
   log_msg "zfs swap /dev/zvol"
   zfs create  -V $SWAP_VOL_SIZE -s $POOL/swap
   mkswap  /dev/zvol/$POOL/swap
   swapon /dev/zvol/$POOL/swap
fi
