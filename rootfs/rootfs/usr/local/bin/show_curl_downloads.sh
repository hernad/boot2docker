#!/bin/sh

. /etc/green_common

REGEX="curl.*\.tar\.[xg]z$"
if ps ax |  grep -q -e  "$REGEX" ; then
  echo -e
  echo "curl downloads in progress:"
  echo_line
  ps ax | grep -e "$REGEX" | awk '{print $7}'
else
  echo "no curl downloads in progress ($REGEX)"
fi
