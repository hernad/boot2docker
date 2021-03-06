#!/bin/bash

. /etc/green_common

sethostname

log_msg "dhcp - udhcpc start"

/sbin/udevadm settle --timeout=5 # This waits until all devices have registered

NETDEVICES="$(awk -F: '/eth.:|tr.:/{print $1}' /proc/net/dev | sort 2>/dev/null)"

if is_x3x50M4_server ; then
  modprobe bonding
  ifconfig eth0 down
  ifconfig eth1 down
  ifconfig eth2 down
  ifconfig eth3 down
  ifconfig bond0 up
  # eth0, eth1, eth2 bonding
  for i in $NETDEVICES ; do
     log_msg "+$i /sys/class/net/bond0/bonding/slaves"
     echo "+${i}" > /sys/class/net/bond0/bonding/slaves
  done
  NETDEVICES="bond0"
  log_msg "x3x50M4_server bond0 `cat /sys/class/net/bond0/bonding/mode`" M

fi

FQDN="$(/bin/hostname)"
HOSTNAME="$(/bin/hostname -s)"
log_msg "HOSTNAME: $HOSTNAME" M

for DEVICE in $NETDEVICES; do
  ifconfig $DEVICE | grep -q "inet addr"
  if [ "$?" != 0 ]; then
    #-x hostname:bbox - option 12
    #-x lease:3600 - option 51 (lease time)
    #-x 0x3d:0100BEEFC0FFEE - option 61 (client id)

    log_msg "Network device $DEVICE detected, DHCP broadcasting for IP"
    trap 2 3 11
    /sbin/udhcpc -b -i $DEVICE \
       --fqdn $FQDN \
       -x "hostname:$HOSTNAME" \
       -x "lease:3600" \ # 60 min
       -s /usr/share/udhcpc/default.script \
       -p /var/run/udhcpc.$DEVICE.pid >/dev/null 2>&1 &
    trap "" 2 3 11
    sleep 1
  fi
done
