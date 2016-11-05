#!/bin/bash

mkdir /opt/apps/x11/lib/

LDD_CHECK="/opt/apps/code/code /opt/apps/atom/bin/atom /opt/apps/java/jre/lib/amd64/ldprism_sw.so /opt/apps/java/jre/lib/amd64/ldprism_es2.so"

FILES_FULLPATH=`ldd | awk '{print $3 }'`
FILES=`ldd $LDD_CHECK | awk '{print $3 }' | sed -e 's/^.*\/\(lib\([xXa-zA-Z0-9._+]\|-\)\+\)$/\1/'`

for f in $FILES ; do

   echo $f

   f_rootfs=`find /rootfs -name $f`
   if [ -z "$f_rootfs" ] ; then
      echo "$f nema u rootfs"

      for fp in $FILES_FULLPATH ; do
         [ -n "$f" ] && [[ "$fp" =~ "$f" ]]  && echo kopirati $fp && cp -av $fp /opt/apps/x11/lib/
      done
   fi
done
