#!/bin/sh

. /etc/green_common

set_path_ld_library
export PATH
export LD_LIBRARY_PATH
export TERM=linux

echo_line() {
  echo "----------------------------------------------------------------"
}

echo -e
echo "zfs mount points"
echo_line

mount | grep "type zfs" | awk '{print $1 " -> "  $3}'

if ps ax | grep -q curl.*.tar.gz$ ; then
  echo -e
  echo "curl downloads in progres:"
  echo_line
  ps ax | grep curl.*.tar.gz$ | awk '{print $7}'
fi
echo -e
[ -e /usr/bin/python ] && echo "`/usr/bin/python --version`"
[ -e /usr/bin/perl ] && echo "`perl -v | sed -n '/This is perl/,2p'`"
echo "VirtualBox: `VBoxManage --version`"
echo -e
echo_line
echo "MY Public IP: `curl ifconfig.co`,  adsl.out.ba IP: `dig +short adsl.out.ba` "
echo -e
echo_line
echo "PATH: $PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo -e
echo_line
echo "greenbox version $(cat /etc/sysconfig/greenbox), build $(cat /etc/sysconfig/greenbox_build)"
echo "docker: `docker -v`"
echo -e
