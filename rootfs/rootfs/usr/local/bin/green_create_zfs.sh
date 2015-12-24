#!/bin/sh

POOL=green

. /etc/rc.d/green_common

if ( ! zpool list $POOL )
then
   log_msg "zpool $POOL doesn't exists"
fi

zfs create -o mountpount /opt/boot green/opt_boot
zfs create -o mountpount /opt/apps green/opt_apps
zfs create -o mountpoint=/home/docker -o quota=50G green/docker_home
zfs create -o mountpoint=/build -o quota=30G green/build

zfs create -V 30G -s -o sync=disabled green/docker_vol
mkfs.ext4 /dev/zvol/green/docker_vol

