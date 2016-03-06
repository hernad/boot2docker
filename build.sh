#!/bin/bash

DOCKER_CACHE=${DOCKER_CACHE:-}

if [ $# -lt 1 ] ; then
   echo "usage: $0 greenbox apps"
   echo "       $0 greenbox"
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

cp isolinux.cfg.$GREEN_PRODUCTION ./rootfs/isolinux/isolinux.cfg

while [ "$arg" ]
do
 
  case $arg in
      greenbox)
         docker rmi -f greenbox:$DOCKER_VERSION
         docker build $DOCKER_CACHE -t greenbox:$DOCKER_VERSION .
         ;;
     apps)
         docker rmi -f greenbox_apps:$DOCKER_VERSION
         docker build $DOCKER_CACHE -t greenbox_apps:$DOCKER_VERSION -f Dockerfile.apps .
         ;;
  esac

  arg=$1
  shift

done
