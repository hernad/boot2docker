#!/bin/sh

echo rm unused containers
docker ps -a | grep  Exited | awk '{print $1}' | xargs docker rm -f

echo rm \<none\> images
docker images | grep "<none>" | awk '{print $3}'  | xargs docker rmi
