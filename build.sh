#!/bin/bash

DOCKER_BUILD_OPTS=${DOCKER_BUILD_OPTS:-}

if [ $# -lt 1 ] ; then
   echo "usage: $0 greenbox apps"
   echo "       $0 greenbox"
   echo "envars: GREEN_PRODUCTION: (rack|vbox)"
   exit 1
fi

arg=$1
shift

DOCKER_VERSION=`cat DOCKER_VERSION`
KERNEL_VERSION=`cat KERNEL_VERSION`
sed -e "s/XBuildX/$(date +'%Y%m%d-%T %z')/g" motd.template |\
  sed -e "s/XDockerX/$DOCKER_VERSION/g" \
  > ./rootfs/rootfs/usr/local/etc/motd

sed -e "s/XBuildX/$(date +'%Y%m%d-%T %z')/g" motd.template |\
  sed -e "s/XDockerX/$DOCKER_VERSION/g" \
  > ./rootfs/rootfs/usr/local/etc/motd



cat ./rootfs/rootfs/usr/local/etc/motd && \
cp  ./rootfs/rootfs/usr/local/etc/motd  ./rootfs/isolinux/boot.msg || ( echo error && exit 1)

GREEN_PRODUCTION=${GREEN_PRODUCTION:-rack}


if [ "$GREEN_PRODUCTION" == "rack" ] ; then
   ISO_DEFAULT=rack
else
   ISO_DEFAULT=vbox
fi

ISO_APPEND="append loglevel=3 user=docker user_password=test01 lang=bs_BA.UTF-8"
ISO_APPEND+=" nozswap nofstab tz=CET-1CEST,M3.5.0,M10.5.0\/3"
ISO_APPEND+=" noembed nomodeset norestore waitusb=10 LABEL=GREEN_HDD"

echo $ISO_APPEND
sed  -e "s/{{ISO_APPEND}}/${ISO_APPEND}/" \
      -e "s/{{ISO_APPEND}}/${ISO_APPEND}/" \
      -e "s/{{ISO_DEFAULT}}/${ISO_DEFAULT}/" \
      isolinux.cfg.template > rootfs/isolinux/isolinux.cfg

while [ "$arg" ]
do
 
  case $arg in
      greenbox)
         docker rmi -f greenbox:$DOCKER_VERSION
         docker build $DOCKER_BUILD_OPTS -t greenbox:$DOCKER_VERSION .
         ;;
     apps)
         docker rmi -f greenbox_apps:$DOCKER_VERSION
         docker build $DOCKER_BUILD_OPTS -t greenbox_apps:$DOCKER_VERSION -f Dockerfile.apps .
         ;;
  esac

  arg=$1
  shift

done
