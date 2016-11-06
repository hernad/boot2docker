#!/bin/sh

. /etc/green_common

show_line " zpool status: "
sudo zpool list -v
echo_line

echo -e
echo_line "zfs mount points"
echo -e
mount | grep "type zfs" | awk '{print $1 " -> "  $3}'
