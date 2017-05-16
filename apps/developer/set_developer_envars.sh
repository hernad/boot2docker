#!/bin/bash

echo "=========== set developer envars ======"
echo -e
echo  "RUN cmd: \$ source $0 ====="

CFLAGS="-I/opt/apps/green/include -I/opt/apps/python2/include"
CFLAGS="$CFLAGS -I/opt/apps/developer/include "
#linux includes
CFLAGS="$CFLAGS -I/opt/apps/developer/include/linux/x86/include -I/opt/apps/developer/include/linux/x86/include/generated"
CFLAGS="$CFLAGS -I/opt/apps/developer/include/linux/x86/include/uapi -I/opt/apps/developer/include/linux/x86/include/generated/uapi"
CFLAGS="$CFLAGS -I/opt/apps/developer/include/linux/include -I/opt/apps/developer/include/linux/include/uapi"

CPPFLAGS="$CFLAGS"
LDFLAGS="-L/opt/apps/green/lib -L/opt/apps/python2/lib -L/opt/apps/developer/lib"

export CFLAGS CPPFLAGS LDFLAGS


echo CFLAGS=$CFLAGS
echo CPPFLAGS=$CPPFLAGS
echo LDFLAGS=$LDFLAGS
