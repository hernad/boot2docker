#!/bin/sh

. /etc/green_common

log_msg "== bootscript.sh: $(date) ===="

log_msg "configure sysctl"
/etc/rc.d/sysctl

log_msg "automount_zfs"
/etc/rc.d/automount_zfs

sleep 3
date
ip a >> $LOG_FILE

let count=0
while ( ! zfs_up ) && [ $count -lt 10 ]
do
  log_msg "cekam zfs_up"
  sleep 1
  let count=count+1
done

log_msg "if VirtualBox create green pool"
/usr/local/bin/vbox_create_pool.sh
/usr/local/bin/green_create_zfs.sh

let count=0
log_msg "setup $BOOT_DIR for mountOnGreen"
[ ! -d $BOOT_DIR ] &&  mkdir -p $BOOT_DIR
if ( ! mountedOnGreen opt_boot ); then
     [ -d $BOOT_DIR ] && mv $BOOT_DIR ${BOOT_DIR}.tmp
     mkdir -p $BOOT_DIR
fi

while ( ! mountedOnGreen opt_boot ) && [ $count -lt 10 ]
do
   zfs_up
   sleep 1

   zfs mount -o mountpoint=$BOOT_DIR green/opt_boot
   log_msg "waiting for mount zfs $BOOT_DIR"
   sleep 1
   let count=count+1
done

[ -d ${BOOT_DIR}.tmp ] && mv ${BOOT_DIR}.tmp/* ${BOOT_DIR}/
[ -d ${BOOT_DIR}.tmp ] && rm -f ${BOOT_DIR}.tmp


log_msg "automount GREEN_volumes"
/etc/rc.d/automount

[ -d $BOOT_DIR/log ] || mkdir -p $BOOT_DIR/log
[ -f $BOOT_DIR/log/udhcp.log ] || rm $BOOT_DIR/log/udhcp.log

#[ -d $BOOT_DIR/certs ] || mkdir -p $BOOT_DIR/certs
#if [ -d /usr/local/etc/ssl/certs ]
#then
#  mv /usr/local/etc/ssl/certs/* $BOOT_DIR/certs/
#  rm -r -f /usr/local/etc/ssl/certs
#fi
#ln -s $BOOT_DIR/certs /usr/local/etc/ssl/certs

# http://serverfault.com/questions/151157/ubuntu-10-04-curl-how-do-i-fix-update-the-ca-bundle
#CA_BUNDLE=/usr/local/etc/ssl/certs/ca-certificates.crt
#[ -f $CA_BUNDLE ] || wget http://curl.haxx.se/ca/cacert.pem -O $CA_BUNDLE


log_msg "mount cgroups hierarchy"
/etc/rc.d/cgroupfs-mount
# see https://github.com/tianon/cgroupfs-mount

log_msg "import settings from profile (or unset them) $BOOT_DIR/profile"
test -f $BOOT_DIR/profile && . $BOOT_DIR/profile

log_msg "set the hostname"
/etc/rc.d/hostname

log_msg "sync the clock"
/etc/rc.d/ntpd &

log_msg "start cron"
/etc/rc.d/crond

log_msg "setup docker user - docker group"

if grep -q '^docker:' /etc/passwd; then
    # if we have the docker user, let's create the docker group
    /bin/addgroup -S docker
    # ... and add our docker user to it!
    /bin/addgroup docker docker

    #preload data from grenbox-cli
    #if [ -e "$BOOT_DIR/userdata.tar" ]; then
    #    tar xf $BOOT_DIR/userdata.tar -C /home/docker/ >> $LOG_FILE  2>&1
    #    rm -f 'greenbox, please format-me'
    #    chown -R docker:staff /home/docker
    #fi
fi

log_msg "init tiny.core applications (/usr/local/tce.installed)"
/etc/rc.d/tce-loader

log_msg "launch ACPID"
/etc/rc.d/acpid

log_msg "start openssh server"
/etc/rc.d/sshd


log_msg "virtualbox drivers"
/etc/rc.d/virtualbox

log_msg "$BOOT_DIR/bootlocal.sh - run local customisation commands"
if [ -e $BOOT_DIR/bootlocal.sh ]; then
    $BOOT_DIR/bootlocal.sh &
    log_msg "after $BOOT_DIR/bootlocal.sh"
fi


log_msg "ldconfg after mounting apps"
/sbin/ldconfig -v >> $LOG_FILE 2>&1

log_msg "launch Docker"
/etc/rc.d/docker

log_msg "locale-archive localedef start"
if [ ! -f $BOOT_DIR/locale/locale-archive ] ; then
   echo -n "${BLUE}localedef en_US.UTF-8 bs_BA.UTF-8${NORMAL}"
   mkdir -p $BOOT_DIR/locale
   ln -s $BOOT_DIR/locale /usr/lib/locale
   /usr/bin/localedef -i en_US -f UTF-8 en_US
   /usr/bin/localedef -i bs_BA -f UTF-8 bs_BA
fi

nohup /usr/local/bin/install_green_apps &
