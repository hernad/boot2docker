#!/bin/bash

. /etc/green_common

let count=0
log_msg "setup $BOOT_DIR for mountOnGreen" B
[ ! -d $BOOT_DIR ] &&  mkdir -p $BOOT_DIR

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
