#!/bin/sh
# The DHCP portion is now separated out, in order to not slow the boot down
# only to wait for slow network cards
. /etc/green_common

sethostname

log_msg "dhcp - udhcpc start"

/sbin/udevadm settle --timeout=5 # This waits until all devices have registered

if is_x3x50M4_server ; then
  # eth0, eth1, eth2 bonding
  NETDEVICES="bond0 eth3"
  modprobe bonding
  ifconfig bond0 up
  ifconfig eth0 down
  ifconfig eth1 down
  ifconfig eth2 down
  echo "+eth0" > /sys/class/net/bond0/bonding/slaves
  echo "+eth1" > /sys/class/net/bond0/bonding/slaves
  echo "+eth2" > /sys/class/net/bond0/bonding/slaves
  log_msg "x3x50M4_server bond0 `cat /sys/class/net/bond0/bonding/mode`" M

else
  NETDEVICES="$(awk -F: '/eth.:|tr.:/{print $1}' /proc/net/dev | sort 2>/dev/null)"
fi

FQDN="$(/bin/hostname)"
HOSTNAME="$(/bin/hostname -s)"
log_msg "HOSTNAME: $HOSTNAME" M

for DEVICE in $NETDEVICES; do
  ifconfig $DEVICE | grep -q "inet addr"
  if [ "$?" != 0 ]; then
    log_msg "Network device $DEVICE detected, DHCP broadcasting for IP"
    trap 2 3 11
    /sbin/udhcpc -b -i $DEVICE \
       --fqdn $FQDN \
       -x hostname:$HOSTNAME \
       -s /usr/share/udhcpc/default.script \
       -p /var/run/udhcpc.$DEVICE.pid >/dev/null 2>&1 &
    trap "" 2 3 11
    sleep 1
  fi
done
