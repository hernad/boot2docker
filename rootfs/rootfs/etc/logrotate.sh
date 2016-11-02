#!/bin/sh

. /etc/green_common

logrotate -s $BOOT_DIR/log/logrotate.status $BOOT_DIR/etc/logrotate.conf
