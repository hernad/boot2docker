#!/bin/sh
. /etc/green_common

echo "${YELLOW}Running boot2docker shutdown script...${NORMAL}"

/usr/local/etc/init.d/docker stop
