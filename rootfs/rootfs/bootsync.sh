#!/bin/sh
. /etc/init.d/tc-functions

echo "${YELLOW}Running greenbox init script...${NORMAL}"

# This log is started before the persistence partition is mounted
/opt/bootscript.sh 2>&1 | tee -a /var/log/greenbox.log


echo "${YELLOW}Finished greenbox init script...${NORMAL}"
