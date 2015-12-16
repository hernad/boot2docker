#!/bin/bash

if [ $# -lt 1 ] ; then
   echo "usage: $0 greenbox apps"
   echo "       $0 greenbox"
   exit 1
fi

arg=$1
shift

DOCKER_VERSION=`cat DOCKER_VERSION`

while [ "$arg" ]
do
 

  case $arg in
      greenbox)
         docker rmi -f greenbox:$DOCKER_VERSION
         docker build -t greenbox:$DOCKER_VERSION .
         ;;
     apps)
         docker rmi -f greenbox_apps:$DOCKER_VERSION
         docker build -t greenbox_apps:$DOCKER_VERSION -f Dockerfile.apps .
         ;;
  esac

  arg=$1
  shift

done
