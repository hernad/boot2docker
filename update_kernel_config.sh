#!/bin/bash

GREENBOX_VERSION=`cat GREENBOX_VERSION`

docker run --rm -t greenbox:$GREENBOX_VERSION sh -c "cat /usr/src/linux/.config"  > kernel_config

