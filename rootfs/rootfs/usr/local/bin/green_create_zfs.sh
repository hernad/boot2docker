#!/bin/sh

zfs create -o mountpount /opt/boot green/opt_boot
zfs create -o mountpount /opt/apps green/opt_apps
zfs create -o mountpoint=/home/docker -o quota=50G green/docker_home
zfs create -o mountpoint=/build -o quota=30G green/build

sudo zfs create -V 30G -s -o sync=disabled green/docker_vol
sudo mkfs.ext4 /dev/zvol/green/docker_vol

