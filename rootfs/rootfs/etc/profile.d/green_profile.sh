#!/bin/sh

. /etc/green_common

mount_all_apps

set_path_ld_library
export PATH
export LD_LIBRARY_PATH


export TERM=linux

[ -e /usr/bin/python ] && echo "python: `/usr/bin/python --version`"
[ -e /usr/bin/perl ] && echo "perl: `perl -v | sed -n '/This is perl/,2p'`"


echo "greenbox version $(cat /etc/sysconfig/greenbox), build $(cat /etc/sysconfig/greenbox_build)"
echo "docker: `docker -v`"
echo "PATH: $PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

echo -e
echo "zfs mount points"
echo "----------------------------------------------------------"
mount | grep "type zfs" | awk '{print $1 " -> "  $3}'

if ps ax | grep -q curl.*.tar.gz$ ; then
  echo -e
  echo "curl downloads in progres:"
  echo "----------------------------------------------------------"
  ps ax | grep curl.*.tar.gz$ | awk '{print $7}'
fi
