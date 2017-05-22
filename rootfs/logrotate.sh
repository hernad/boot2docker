#!/bin/sh

. /etc/green_common

log_msg "logrotate.sh start"
logrotate -s $BOOT_DIR/log/logrotate.status $BOOT_DIR/etc/logrotate.conf
