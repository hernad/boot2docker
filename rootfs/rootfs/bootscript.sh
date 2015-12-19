#!/bin/sh

BOOT_DIR=/opt/boot
LOG_FILE=/var/log/greenbox.log

[ -d $BOOT_DIR/log ] || mkdir -p $BOOT_DIR/log
[ -f $BOOT_DIR/log/udhcp.log ] || rm $BOOT_DIR/log/udhcp.log

echo "== bootscript.sh: $(date) ====" >> $LOG_FILE
echo "configure sysctl" >> $LOG_FILE
/etc/rc.d/sysctl

log_msg () {
  echo "bootscript.sh: $1" >> $LOG_FILE
}

log_msg "automount_zfs"
/etc/rc.d/automount_zfs

log_msg "mount cgroups hierarchy"
/etc/rc.d/cgroupfs-mount
# see https://github.com/tianon/cgroupfs-mount

log_msg "import settings from profile (or unset them)"
test -f $BOOT_DIR/profile && . $BOOT_DIR/profile

log_msg "set the hostname"
/etc/rc.d/hostname

log_msg "sync the clock"
/etc/rc.d/ntpd &

log_msg "start cron"
/etc/rc.d/crond

log_msg "add docker:docker user"

if grep -q '^docker:' /etc/passwd; then
    # if we have the docker user, let's create the docker group
    /bin/addgroup -S docker
    # ... and add our docker user to it!
    /bin/addgroup docker docker

    #preload data from grenbox-cli
    if [ -e "$BOOT_DIR/userdata.tar" ]; then
        tar xf $BOOT_DIR/userdata.tar -C /home/docker/ >> $LOG_FILE  2>&1
        rm -f 'greenbox, please format-me'
        chown -R docker:staff /home/docker
    fi
fi

log_msg "automount shared folders (VirtualBox, etc.)"
/etc/rc.d/automount-shares

log_msg "configure SSHD"
/etc/rc.d/sshd

log_msg "launch ACPID"
/etc/rc.d/acpid

echo "-------------------"
date
#maybe the links will be up by now - trouble is, on some setups, they may never happen, so we can't just wait until they are
sleep 5
date
ip a
echo "-------------------"

# Allow local bootsync.sh customisation
if [ -e $BOOT_DIR/bootsync.sh ]; then
    $BOOT_DIR/bootsync.sh
    log_msg "after $BOOT_DIR/bootsync.sh"
fi

log_msg "Launch Docker"
/etc/rc.d/docker

log_msg "virtualbox drivers"
/etc/rc.d/virtualbox

log_msg "bootlocal.sh - allow local HD customisation"
if [ -e $BOOT_DIR/bootlocal.sh ]; then
    $BOOT_DIR/bootlocal.sh &
    log_msg "after $BOOT_DIR/bootlocal.sh"
fi

log_msg "before: download_green_apps"
. /usr/local/bin/download_green_apps

