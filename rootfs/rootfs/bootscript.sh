#!/bin/sh

BOOT_DIR=/opt/boot
LOG_FILE=/var/log/bootscript.log

# Configure sysctl
/etc/rc.d/sysctl

# Load TCE extensions
/etc/rc.d/tce-loader

/etc/rc.d/automount_zfs

# Mount cgroups hierarchy
/etc/rc.d/cgroupfs-mount
# see https://github.com/tianon/cgroupfs-mount

[ -d $BOOT_DIR/log ] || mkdir -p $BOOT_DIR/log
[ -f $BOOT_DIR/log/udhcp.log ] || rm $BOOT_DIR/log/udhcp.log

#import settings from profile (or unset them)
test -f $BOOT_DIR/profile && . $BOOT_DIR/profile

# set the hostname
/etc/rc.d/hostname

# sync the clock
/etc/rc.d/ntpd &

# start cron
/etc/rc.d/crond


# TODO: move this (and the docker user creation&pwd out to its own over-rideable?))
if grep -q '^docker:' /etc/passwd; then
    # if we have the docker user, let's create the docker group
    /bin/addgroup -S docker
    # ... and add our docker user to it!
    /bin/addgroup docker docker

    #preload data from grenbox-cli
    if [ -e "$BOOT_DIR/userdata.tar" ]; then
        tar xf $BOOT_DIR/userdata.tar -C /home/docker/ > /var/log/userdata.log 2>&1
        rm -f 'greenbox, please format-me'
        chown -R docker:staff /home/docker
    fi
fi

# Automount Shared Folders (VirtualBox, etc.)
/etc/rc.d/automount-shares

# Configure SSHD
/etc/rc.d/sshd

# Launch ACPId
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
    echo "------------------- ran $BOOT_DIR/bootsync.sh"
fi

# Launch Docker
/etc/rc.d/docker

/etc/rc.d/virtualbox

# Allow local HD customisation
if [ -e $BOOT_DIR/bootlocal.sh ]; then
    $BOOT_DIR/bootlocal.sh > /var/log/bootlocal.log 2>&1 &
    echo "------------------- ran $BOOT_DIR/bootlocal.sh"
fi


mount_opt() {

if [ -d /opt/apps/$1 ] ; then
  if ! $(grep -q \/opt\/$1 /proc/mounts) ; then
    echo mkdir, mount /opt/apps/$1 ...
    sudo mkdir -p /opt/$1
    sudo mount --bind /opt/apps/$1 /opt/$1 >> $LOG_FILE
    echo "/opt/$1 mounted" >> $LOG_FILE
  fi
fi

}

export GREEN_BINTRAY=${GREEN_BINTRAY:-https://dl.bintray.com/hernad/greenbox}
export GREEN_APPS=${GREEN_APPS:-green_1.0.0 VirtualBox_5.0.10 vagrant_1.7.4 python2_2.7.11 nvim_0.1.1-79 vim_7.4.972 node_5.2.0}

for appver in $GREEN_APPS; do

   # VirtualBox_5.0.10
   app=$( echo $appver | cut -d"_" -f1 )
   ver=$( echo $appver | cut -d"_" -f2 )

   if $(grep -q \/opt\/apps /proc/mounts) && [ ! -d /opt/apps/${app} ] ; then
         cd /tmp 
         ( curl -LO $GREEN_BINTRAY/${app}_${ver}.tar.gz || \
          ( echo "curl $GREEN_BINTRAY/${app}_${ver}.tar.gz ERROR" >> /opt/boot/log/download_apps.log && false ) \
         ) &&\
         cd /opt/apps/ && tar xvf /tmp/${app}_${ver}.tar.gz &&\
         rm /tmp/${app}_${ver}.tar.gz
   fi

   if [ -d /opt/apps/${app} ] ; then
       if [ "$app" == "VirtualBox" ]; then
           # VirtualBox execs has to be root
           chown root:root -R /opt/apps/${app}
       fi 
   fi
done

for app in `ls -1 /opt/apps`
do
   if [ -d /opt/apps/${app} ] ; then
       mount_opt ${app}
   fi
done


