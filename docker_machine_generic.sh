#!/bin/bash

[ -z "$1" ] && echo prvi argument ip && exit 1
[ -z "$2" ] && echo drugi argument machine name && exit 1

docker-machine create \
  --driver generic \
  --generic-ip-address=$1 \
  --generic-ssh-key ~/.ssh/id_rsa \
  --generic-ssh-user docker \
   $2
