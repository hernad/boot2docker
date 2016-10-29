#!/bin/sh

for appdir in `ls -1 /opt`
do
   if [ -d /opt/$appdir/lib ] ; then
      LD_LIBRARY_PATH=/opt/$appdir/lib:$LD_LIBRARY_PATH
   fi

   if [ -d /opt/$appdir/bin ] ; then
      PATH=/opt/$appdir/bin:$PATH
   else
      if  [ -d /opt/$appdir ] && [ "$appdir" != "apps" ] && [ "$appdir" != "boot" ] ; then
         export PATH=/opt/$appdir:$PATH
      fi
   fi
done

export PATH
export LD_LIBRARY_PATH

export TERM=linux

[ -e /usr/bin/python ] && echo "python: `/usr/bin/python --version`"
[ -e /usr/bin/perl ] && echo "perl: `/usr/bin/perl --version`"

echo "greenbox version $(cat /etc/sysconfig/greenbox), build $(cat /etc/sysconfig/greenbox_build)"
echo "docker: `docker -v`"
echo "PATH: $PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

echo "zfs mount points"
echo "----------------------------------------------------------"
mount | grep "type zfs" | awk '{print $1 " -> "  $3}'

if ps ax | grep -q curl.*.tar.gz$ ; then
  echo -e
  echo "curl downloads in progres:"
  echo "----------------------------------------------------------"
  ps ax | grep curl.*.tar.gz$ | awk '{print $7}'
fi
