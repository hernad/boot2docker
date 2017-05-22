#!/bin/sh
# The DHCP portion is now separated out, in order to not slow the boot down
# only to wait for slow network cards
. /etc/green_common

if [ ! -e $BOOT_DIR/etc/hostname ]; then
    cp /usr/local/etc/hostname $BOOT_DIR/etc/hostname
fi
HOSTNAME=`cat $BOOT_DIR/etc/hostname`
log_msg "set the hostname: $HOSTNAME" B
/usr/bin/sethostname $HOSTNAME


log_msg "dhcp - udhcpc start"

/sbin/udevadm settle --timeout=5 # This waits until all devices have registered

NETDEVICES="$(awk -F: '/eth.:|tr.:/{print $1}' /proc/net/dev 2>/dev/null)"

log_msg "network devices: $NETDEVICES" M

for DEVICE in $NETDEVICES; do
  ifconfig $DEVICE | grep -q "inet addr"
  if [ "$?" != 0 ]; then
    log_msg "Network device $DEVICE$ detected, DHCP broadcasting for IP"
    trap 2 3 11
    /sbin/udhcpc -b -i $DEVICE -x hostname:$(/bin/hostname) -p /var/run/udhcpc.$DEVICE.pid >/dev/null 2>&1 &
    trap "" 2 3 11
    sleep 1
  fi
done
