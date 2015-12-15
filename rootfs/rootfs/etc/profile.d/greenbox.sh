#!/bin/sh



for appdir in `ls -1 /opt`
do
   if [ -d /opt/$appdir/bin ] ; then
      PATH=/opt/$appdir/bin:$PATH
   else
      if  [ -d /opt/$appdir ] ; then
         PATH=/opt/$appdir:$PATH
      fi
   fi
done

export PATH

echo "greenbox version $(cat /etc/version), build $(cat /etc/boot2docker)"
docker -v # e.g. Docker version 1.3.0-dev, build ba14ddf-dirty
echo "PATH: $PATH"
