#!/bin/sh
. /etc/green_common

echo "${YELLOW}Running boot2docker shutdown script...${NORMAL}"

/etc/init.d/docker stop
