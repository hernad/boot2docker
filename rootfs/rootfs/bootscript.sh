#!/bin/sh

. /etc/green_common

log_msg "== bootscript.sh: $(date) ====" G

log_msg "configure sysctl"
/etc/rc.d/automount_zfs
sleep 2
date
ip a >> $LOG_FILE

let count=0
while ( ! zfs_up ) && [ $count -lt 10 ]
do
  log_msg "waiting zfs_up ..." B
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
   sleep 3
   if zfs_up ; then
     zfs mount -o mountpoint=$BOOT_DIR green/opt_boot
     sleep 1
   else
     log_msg "zfs is not up waiting ..." B
   fi
   let count=count+1
done

if ( mountedOnGreen docker_home ); then
				if [ ! -d ${DOCKER_HOME_DIR}/.config ] ; then
				  mkdir -p ${DOCKER_HOME_DIR}/.config
					cat > ${DOCKER_HOME_DIR}/.profile <<EOF
# ~/.profile: Executed by BASH.
export PATH=\$HOME/.local/bin:\$PATH
[ -d "\$HOME/.local/bin" ] || mkdir -p "\$HOME/.local/bin"
export PATH=\$HOME/.local/bin:\$PATH

#PAGER='less -EM'
#MANPAGER='less -isR'
EDITOR=vim
#TERMTYPE=`/usr/bin/tty`
#[ "${TERMTYPE:5:3}" == "tty" ] && (
#	[ ! -f /etc/sysconfig/Xserver ] ||
#	[ -f /etc/sysconfig/text ] ||
#	[ -e /tmp/.X11-unix/X0 ] || startx
#)
EOF
          chown -R docker:docker ${DOCKER_HOME_DIR}/.profile
				fi
else

	    echo "${RED}Docker home not mounted ERROR!${NORMAL}"

fi

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
  log_msg "bootstrap ca-certs from etc_ssl.tar.xz" B
  count=0
  cd $BOOT_DIR/etc
  while ! curl -skLO ${DOWNLOAD_URL}/etc_ssl.tar.xz && [ $count -lt 10 ]
  do
    log_msg "curl ${DOWNLOAD_URL}/etc_ssl.tar.xz ERROR ($count)" R
    sleep 5
    let count=count+1
  done
  if [ $count -ge 9 ] ; then
    log_msg "curl ${DOWNLOAD_URL}/etc_ssl.tar.xz CANNOT BE DOWNLOADED" R
  else
    log_msg "curl ${DOWNLOAD_URL}/etc_ssl.tar.xz DOWNLOADED" G
  fi
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
ln -s $BOOT_DIR/root /root
[ -d /root.orig ]  && mv /root.orig/* /root/ && rm -rf /root.orig

echo "${GREEN}KERNEL cmdline:${NORMAL}  `cat /proc/cmdline`"

/etc/rc.d/sysctl
/etc/rc.d/acpid
/etc/rc.d/sshd start
/etc/rc.d/server_scaleway
/etc/rc.d/server_vultr
/etc/rc.d/vbox_kernel
/etc/rc.d/tce_postinstall


if [ ! -f $BOOT_DIR/locale/locale-archive ] ; then
   # http://manpages.ubuntu.com/manpages/trusty/man1/localedef.1.html
   log_msg "locale-archive localedef start" B
   mkdir -p $BOOT_DIR/locale
   cd $BOOT_DIR/locale
   if ! curl -skLO ${DOWNLOAD_URL}/usr_share_i18n.tar.xz ; then
      log_msg "curl ${DOWNLOAD_URL}/usr_share_i18n.tar.xz ERROR" R
   else
     tar xf usr_share_i18n.tar.xz
     if [ $? -eq 0 ] ; then
       log_msg "curl ${DOWNLOAD_URL}/usr_share_i18n.tar.xz OK" G
     fi
     rm usr_share_i18n.tar.xz
     ln -s $BOOT_DIR/locale /usr/lib/locale
     ln -s $BOOT_DIR/locale/i18n /usr/share/i18n
   fi
   localedef --force -i en_US -f UTF-8 en_US.UTF-8 >> LOG_FILE 2>&1
   localedef --force -i bs_BA -f UTF-8 bs_BA.UTF-8 >> LOG_FILE 2>&1
   if [ -f $BOOT_DIR/locale/locale-archive ] ; then
     log_msg "localedef $BOOT_DIR/locale/locale-archive" G
   else
     log_msg "localedef $BOOT_DIR/locale/locale-archive NOT CREATED" R
   fi
fi
[ -L /usr/lib/locale ] || ln -s $BOOT_DIR/locale /usr/lib/locale
[ -L /usr/share/i18n ] || ln -s $BOOT_DIR/locale/i18n /usr/share/i18n


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
