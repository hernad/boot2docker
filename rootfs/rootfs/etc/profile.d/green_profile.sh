#!/bin/sh
. /etc/green_common

sudo su -c ". /etc/green_common ; mount_all_apps ; setup_symlinks_and_commands"
set_path_ld_library

export PATH
export LD_LIBRARY_PATH
export TERM=linux

echo -e
echo_line " Application versions: "
[ -n "`which vim`" ] && echo "`vim --version | grep ^VIM`"
[ -e /usr/bin/python ] && echo "`python -V 2>&1 | xargs`"
[ -e /usr/bin/perl ] && echo "`perl -v | sed -n '/This is perl/,2p'`"
[ -e /opt/VirtualBox/VirtualBox ] && echo "VirtualBox: `VBoxManage --version`"
[ -d /opt/go ] && export GOROOT=/opt/go
[ -n "$GOROOT" ] && export GOPATH=/home/docker/go && mkdir -p $GOPATH && echo "GOPATH=$GOPATH, `/opt/go/bin/go version`"
[ -n "`which npm`" ] && echo nodejs/npm: `npm version | tr  -d '\n' | sed -e 's/,[[:space:]]\+/, /g' | sed -e 's/:[[:space:]]\+/: /g' | tr -d "'"`
[ -d /opt/java ] && export JAVA_HOME=/opt/java
[ -n "$JAVA_HOME" ] && echo "JAVA_HOME=$JAVA_HOME", `/opt/java/bin/java -version 2>&1 | xargs echo`
echo -e
echo_line "    Kernel info:   "
uname -a
echo "ZFS `modinfo zfs | grep "version.*[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]-]\+$"`"
echo -e
echo_line
echo "PATH: $PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo -e
echo_line
echo "greenbox version $(cat /etc/sysconfig/greenbox), build $(cat /etc/sysconfig/greenbox_build)"
echo "docker: `docker -v`"
[ -d /opt/green ] && echo "`docker-compose --version`"

echo -e
[ "`cat /etc/passwd | grep "^tc:" |  awk -F: '{print $7}'`" != "/bin/false" ] && \
   echo -e "${RED}SECURITY hole (tc_login_open) !\nRUN ${GREEN}# disable_tc_login\n${NORMAL}"

[ -d /opt/green ] && git config --global core.pager 'more'  # git diff

# http://www.thegeekstuff.com/2008/09/bash-shell-ps1-10-examples-to-make-your-linux-prompt-like-angelina-jolie/
NOCOLOR="\033[0;0;0m"      # no color or formatting
PCOLOR=${GREEN}
[ $(id -u) = 0 ] && PCOLOR=$RED # root user

#http://unix.stackexchange.com/questions/105958/terminal-prompt-not-wrapping-correctly
PS1="[\[${PCOLOR}\]\u@\h\[${NOCOLOR}\] \W]\\$ " # prompt
