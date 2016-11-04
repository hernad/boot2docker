#!/bin/bash

mkdir /opt/apps/x11/lib/

for JAVA_SO in libprism_sw.so libprism_es2.so ; do

echo -e
echo "================================================"
echo "checking $JAVA_SO"

FILES_FULLPATH=`ldd /opt/apps/java/jre/lib/amd64/$JAVA_SO | awk '{print $3 }'`
FILES=`ldd /opt/apps/java/jre/lib/amd64/$JAVA_SO | awk '{print $3 }' | sed -e 's/^.*\/\(lib\([xXa-zA-Z0-9._+]\|-\)\+\)$/\1/'`

for f in $FILES ; do
   f_rootfs=`find /rootfs -name $f`
   if [ -z "$f_rootfs" ] ; then
      echo "$f nema u rootfs"

      for fp in $FILES_FULLPATH ; do
         [ -n "$f" ] && [[ "$fp" =~ "$f" ]]  && echo kopirati $fp && cp -av $fp /opt/apps/x11/lib/
      done
   fi
done

done
