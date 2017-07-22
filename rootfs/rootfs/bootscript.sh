#!/bin/sh
. /etc/green_common

download_etc_ssl() {

 if [ -d $BOOT_DIR/etc/ssl ] ; then
   # ssl test
   if [ ! -f $BOOT_DIR/etc/ssl/certs/ca-certificates.crt ] ; then
       rm -rf $BOOT_DIR/etc/ssl
   else
       return 0
   fi
 fi

 mkdir -p $BOOT_DIR/etc/ssl
 log_msg "bootstrap ca-certs from etc_ssl.tar.xz" B

 cd $BOOT_DIR/etc

  count=0
  while [ $count -lt 10 ] ; do
    $CURL -skLO ${DOWNLOAD_URL}/etc_ssl.tar.xz && [ $count -lt 10 ]
    if [ $? -ne 0 ] ; then
       log_msg "ERROR: CURL: $DOWNLOAD_URL/etc_ssl.tar.xz" R
       rm etc_ssl.tar.xz
       let count=count+1
    else
       if ! tar -tf etc_ssl.tar.xz > /dev/null 2>&1 ; then
          SIZE=`ls -lh etc_ssl.tar.xz | awk '{print $5}'`
          MD5SUM=`/usr/bin/md5sum etc_ssl.tar.xz | awk '{print $1}'`
          log_msg "etc_ssl.tar.xz is not valid tar, size $SIZE, md5sum: $MD5SUM" R
          rm etc_ssl.tar.xz
          let count=count+1
       else
           let count=999 # download OK
       fi
     fi
  done

  if [ $count -eq 999 ] ; then
    tar xf etc_ssl.tar.xz
    rm etc_ssl.tar.xz
    ln -fs $BOOT_DIR/etc/ssl/certs/ca-certificates.crt $BOOT_DIR/etc/ssl/cacert.pem
    ln -fs $BOOT_DIR/etc/ssl/certs/ca-certificates.crt $BOOT_DIR/etc/ssl/ca-bundle.crt
    # final test
    [ -f $BOOT_DIR/etc/ssl/certs/ca-certificates.crt ]

  else
    return 127
  fi
}

setup_network() {

if [ -n "$STATICIP" ]; then
  	log_msg "Skipping DHCP broadcast/network detection" B
else
  	/etc/init.d/dhcp.sh &
  	/etc/init.d/settime.sh &
fi

}

log_msg "== bootscript.sh: $(date) ====" G

/etc/rc.d/automount_green_init

if [ $FILESYSTEM == "zfs" ] ; then
  /etc/rc.d/automount_zfs
  vbox_create_pool.sh
  cloud_vda_create_pool.sh
  green_create_zfs.sh
  mount_zfs_opt_boot_docker_home.sh
fi

if [ $FILESYSTEM == "btrfs" ] ; then
  /etc/rc.d/automount_btrfs
  vbox_create_btrfs.sh
  cloud_vda_create_pool.sh
  green_create_btrfs_subvols.sh
fi

mkdir -p /home/tc # da se mozemo logirati kao tc user
if  [  ! -d $BOOT_DIR ] ; then
   log_msg "ERROR >>> $BOOT_DIR not exists, login as tc user" R
   setup_network
   exit 1
fi

for f in `ls /opt/apps/*.xz*` ; do
   log_msg "remove broken downloads: rm $f" Y
   rm $f
done

set_log_file

log_msg "import settings from profile (or unset them) $BOOT_DIR/profile"
test -f $BOOT_DIR/profile && . $BOOT_DIR/profile

set_log_file
STATICIP="$(getbootparam staticip 2>/dev/null)"

setup_network

wait4internet

if ! download_etc_ssl ; then
   echo ">>>>>>>>>> curl SSL cannot be set !? <<<<<<<<<<<<<<<<<<<" R
   echo no > /etc/sysconfig/ssl
else
   echo yes > /etc/sysconfig/ssl
fi

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
[ -d /root ] && mv /root /tmp/
ln -s $BOOT_DIR/root /root
#[ -d /root.orig ] && mv /root.orig/* /root/ && rm -rf /root.orig # nema nista u /root

echo "${GREEN}KERNEL cmdline:${NORMAL}  `cat /proc/cmdline`"

/etc/rc.d/ntpd
/etc/rc.d/crond start
/etc/rc.d/sysctl
/etc/rc.d/acpid
/etc/rc.d/sshd start
/etc/rc.d/server_scaleway
/etc/rc.d/server_vultr
/etc/rc.d/vbox_kernel
/etc/rc.d/tce_postinstall
/etc/rc.d/firewall

if [ ! -f $BOOT_DIR/locale/locale-archive ] ; then
   # http://manpages.ubuntu.com/manpages/trusty/man1/localedef.1.html
   log_msg "locale-archive localedef start" B
   mkdir -p $BOOT_DIR/locale
   cd $BOOT_DIR/locale
   if ! $CURL -skLO ${DOWNLOAD_URL}/usr_share_i18n.tar.xz ; then
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

if [ ! -e $BOOT_DIR/etc/profile ] ; then
  cat > $BOOT_DIR/etc/profile <<EOF
# put envars  e.g. GREEN_APPS, HTTP_PROXY, HTTPS_PROXY, DOCKER_OPTS, DOCKER_STORAGE, DOCKER_LOGFILE, CERT_INTERFACES, CERT_DIR
# DOCKER_STORAGE=zfs
# DOCKER_DIR=green/docker
# SYSLOG=1
# FIREWALL=1
# FIREWALL_FWKNOP=bond0  # fwknop listen interface
# PROXY=1
EOF
fi

mount_all_apps
ldcache_update
vbox_fix_permissions

install_green_apps &

if [ -d /opt/apps ] && [ ! -f /opt/apps/docker/VERSION ] ; then
   ( log_msg "docker is not installed, 2nd try after 90sec ..." Y  && sleep 90 && install_green_apps ) & # if there are errors during first install, try again
fi

/etc/init.d/docker start
/etc/rc.d/syslog &
/etc/rc.d/proxy &
/etc/rc.d/opt_boot_init_d_scripts &

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

# ne, ovo zatreba kod inicijalizacije sistema
#sed -i  's/^\(tc.*\)\/bin\/sh$/\1\/bin\/false/'  $BOOT_DIR/etc/passwd # disable_tc_login

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


if ( ! is_vbox ) && cat /proc/cmdline | grep -q "console=ttyS0"
then
	log_msg "start serial console"
	/sbin/getty -L 115200 ttyS0 vt100 & ## moramo pustiti da se bootscript.sh zavrsi
  #$ ps ax | grep init | grep -v grep
  #  1 ?        Ss     0:05 /sbin/init << ok
  #$ ps ax | grep  init
  #  1 ?        Ss     0:07 /sbin/init
  #166 ?        Ss     0:00 /bin/sh /etc/init.d/rcS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  #170 ?        S      0:00 /bin/busybox ash /etc/init.d/tc-config <<<< problematic
fi
