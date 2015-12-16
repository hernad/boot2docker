#!/bin/sh

mount_opt() {

if [ -d /opt/apps/$1 ] ; then
  if ! $(grep -q \/opt\/$1 /proc/mounts) ; then
    echo mkdir, mount /opt/apps/$1 ...
    sudo mkdir -p /opt/$1
    sudo mount --bind /opt/apps/$1 /opt/$1
    echo "/opt/$1 mounted"
  fi
fi
}

for app in `ls -1 /opt/apps`
do
   if [ -d /opt/apps/${app} ] ; then
       mount_opt ${app}
   fi
done

for appdir in `ls -1 /opt`
do
   if [ -d /opt/$appdir/lib ] ; then
      LD_LIBRARY_PATH=/opt/$appdir/lib:$LD_LIBRARY_PATH
   fi

   if [ -d /opt/$appdir/bin ] ; then
      PATH=/opt/$appdir/bin:$PATH
   else
      if  [ -d /opt/$appdir ] && [ "$appdir" != "apps" ] && [ "$appdir" != "boot" ] ; then
         PATH=/opt/$appdir:$PATH
      fi
   fi
done

export PATH
export LD_LIBRARY_PATH

echo "greenbox version $(cat /etc/version), build $(cat /etc/greenbox)"
docker -v # e.g. Docker version 1.3.0-dev, build ba14ddf-dirty
echo "PATH: $PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
