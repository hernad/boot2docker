#!/bin/sh

. /etc/green_common

echo_line
echo "MY Public IP: `curl -s ifconfig.co`,  adsl.out.ba IP: `dig +short adsl.out.ba` "
echo -e
