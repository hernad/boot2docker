#!/bin/sh

. /etc/green_common

: ${SYSTEM_ULIMITS:=1048576}

log_msg "== bootscript.sh: $(date) ====" G

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
vbox_create_pool.sh
cloud_vda_create_pool.sh
green_create_zfs.sh

let count=0
log_msg "setup $BOOT_DIR for mountOnGreen"
[ ! -d $BOOT_DIR ] &&  mkdir -p $BOOT_DIR

#if ( ! mountedOnGreen opt_boot ); then
     #[ -d $BOOT_DIR ] && mv $BOOT_DIR ${BOOT_DIR}.tmp
     #mkdir -p $BOOT_DIR
#fi

while ( ! mountedOnGreen opt_boot ) && [ $count -lt 10 ]
do
   zfs_up
   sleep 3
   zfs mount -o mountpoint=$BOOT_DIR green/opt_boot
   log_msg "waiting for mount zfs $BOOT_DIR"
   sleep 1
   let count=count+1
done

#if [ -d ${BOOT_DIR}.tmp ] ; then
#    mv ${BOOT_DIR}.tmp/* ${BOOT_DIR}/
#    rm -f ${BOOT_DIR}.tmp
#fi

log_msg "automount GREEN_volumes"
/etc/rc.d/automount

[ -d $BOOT_DIR/log ] || mkdir -p $BOOT_DIR/log
[ -f $BOOT_DIR/log/udhcp.log ] && rm $BOOT_DIR/log/udhcp.log

if [ ! -d $BOOT_DIR/etc/ssl ] ; then
  mkdir -p $BOOT_DIR/etc/ssl
  log_msg "bootstrap ca-certs from etc_ssl.tar.xz"
  count=0
  cd $BOOT_DIR/etc
  while ! curl -skLO ${DOWNLOAD_URL}/etc_ssl.tar.xz && [ $count -lt 10 ]
  do
    sleep 5
    let count=count+1
  done
  tar xf etc_ssl.tar.xz
  rm etc_ssl.tar.xz

  ln -fs $BOOT_DIR/etc/ssl/certs/ca-certificates.crt $BOOT_DIR/etc/ssl/cacert.pem
  ln -fs $BOOT_DIR/etc/ssl/certs/ca-certificates.crt $BOOT_DIR/etc/ssl/ca-bundle.crt
fi


set_log_file

log_msg "mount cgroups hierarchy"
/etc/rc.d/cgroupfs-mount
# see https://github.com/tianon/cgroupfs-mount

log_msg "import settings from profile (or unset them) $BOOT_DIR/profile"
test -f $BOOT_DIR/profile && . $BOOT_DIR/profile

set_log_file

log_msg "set the hostname"
/etc/rc.d/hostname

log_msg "sync the clock"
/etc/rc.d/ntpd &
/etc/rc.d/crond start

log_msg "setup docker user - docker group"

if grep -q '^docker:' /etc/passwd; then
    /bin/addgroup -S docker
    /bin/addgroup docker docker

    #preload data from grenbox-cli
    if [ -e "/userdata.tar" ]; then
        tar xf /userdata.tar -C ${DOCKER_HOME_DIR}/ >> $LOG_FILE  2>&1
        rm -f "${DOCKER_HOME_DIR}/greenbox, please format-me"
        chown -R docker:docker ${DOCKER_HOME_DIR}
    fi

    if ls -ld ${DOCKER_HOME_DIR} | grep -q root
    then
       chown -R docker:docker ${DOCKER_HOME_DIR}
    fi
fi

[ -d $BOOT_DIR/root ] || mkdir -p $BOOT_DIR/root
[ -d /root ] && mv /root /root.orig
ln -s $BOOT_DIR/root /root && mv /root.orig/* /root/ && rm -rf /root.orig

echo "${GREEN}KERNEL cmdline:${NORMAL}  `cat /proc/cmdline`"

/etc/rc.d/acpid
/etc/rc.d/sshd start
/etc/rc.d/server_scaleway
/etc/rc.d/server_vultr
/etc/rc.d/vbox_kernel
/etc/rc.d/tce_postinstall

log_msg "locale-archive localedef start"
if [ ! -f $BOOT_DIR/locale/locale-archive ] ; then
   echo -n "${BLUE}localedef en_US.UTF-8 bs_BA.UTF-8${NORMAL}"
   mkdir -p $BOOT_DIR/locale
   ln -s $BOOT_DIR/locale /usr/lib/locale
   localedef -i en_US -f UTF-8 en_US
   localedef -i bs_BA -f UTF-8 bs_BA
fi
[ -L /usr/lib/locale ] || ln -s $BOOT_DIR/locale /usr/lib/locale

mount_all_apps
ldcache_update
vbox_fix_permissions
install_green_apps &

if [ -d /opt/apps ] && [ ! -f /opt/apps/docker/VERSION ] ; then
   log_msg "docker is not installed, wait 90sec ..."
   sleep 90
   install_green_apps & # if there are errors during first install, try again
fi

/etc/rc.d/start_docker_then_opt_boot_init_d_scripts &

log_msg "$BOOT_DIR/bootlocal.sh - run local customization commands"
if [ -e $BOOT_DIR/bootlocal.sh ]; then
    $BOOT_DIR/bootlocal.sh &
    log_msg "after $BOOT_DIR/bootlocal.sh"
fi

for f in passwd shadow shadow- ; do
 if [ ! -f $BOOT_DIR/etc/$f ] ; then
    [ -d $BOOT_DIR/etc ] || mkdir -p $BOOT_DIR/etc
    [ -f /etc/$f ] && mv /etc/$f $BOOT_DIR/etc/$f # ram -> BOOT_DIR
 fi
 [ -f /etc/$f ] && rm /etc/$f
 ln -s $BOOT_DIR/etc/$f /etc/$f
 chown root:root $BOOT_DIR/etc/$f # permanent passwd
done

sed -i  's/^\(tc.*\)\/bin\/sh$/\1\/bin\/false/'  $BOOT_DIR/etc/passwd # disable_tc_login

[ -d $BOOT_DIR/etc/sysconfig ] || mkdir -p $BOOT_DIR/etc/sysconfig
#[ -f $BOOT_DIR/etc/sysconfig/docker ] || mv /etc/sysconfig/docker $BOOT_DIR/etc/sysconfig/ # permanent docker version
#[ -f /etc/sysconfig/docker ] && rm /etc/sysconfig/docker
#ln -s $BOOT_DIR/etc/sysconfig/docker /etc/sysconfig/docker

# setup logrotate.conf
[ -f $BOOT_DIR/etc/logrotate.conf ] || cat > $BOOT_DIR/etc/logrotate.conf <<- EOF
weekly
rotate 4
create 0664 root root
compress
notifempty
$BOOT_DIR/log/*.log {
    monthly
    size 30k
}
include $BOOT_DIR/etc/logrotate.d
EOF
[ -d $BOOT_DIR/etc/logrotate.d ] || mkdir -p $BOOT_DIR/etc/logrotate.d

[ -d $BOOT_DIR/bin ] || mkdir -p $BOOT_DIR/bin

setup_symlinks_and_commands

#https://www.tecmint.com/increase-set-open-file-limits-in-linux/

# Increasing the number of open files and processes by docker

ulimit -n $SYSTEM_ULIMITS
log_msg "ulimit -p $SYSTEM_ULIMITS ($?)  NEW ulimit -n: `ulimit -n`)"

ulimit -p $SYSTEM_ULIMITS
log_msg "ulimit -p $SYSTEM_ULIMITS ($?) NEW ulimit -p: `ulimit -p`"
