#!/bin/bash

docker rm -f apt-cacher-ng
docker run --name apt-cacher-ng -d --restart=always \
  --publish 3142:3142 \
  --volume $(pwd)/apt-cacher-ng:/var/cache/apt-cacher-ng \
  sameersbn/apt-cacher-ng:latest


docker exec apt-cacher-ng ifconfig eth0
