#!/bin/bash

mkdir /opt/apps/x11/lib/

LDD_CHECK="/opt/apps/code/code /opt/apps/atom/bin/atom /opt/apps/java/jre/lib/amd64/libprism_sw.so /opt/apps/java/jre/lib/amd64/libprism_es2.so"
LDD_CHECK+=" /opt/apps/x11/lib/libnss3.so"

for ldd_f in $LDD_CHECK ; do

   echo "=============================== $ldd_f ============================================="
   FILES_FULLPATH_0=`ldd $ldd_f | awk '{print $1 $2 $3 $4}'`
   FILES_FULLPATH=`ldd $ldd_f | awk '{print $3 }'`
   FILES=`ldd $ldd_f | awk '{print $3 }' | sed -e 's/^.*\/\(lib\([xXa-zA-Z0-9._+]\|-\)\+\)$/\1/'`

   for f in $FILES_FULLPATH_0 ; do
        if [[ "$f" =~ "notfound" ]] ; then
            echo ">>>>>>>>>>>>>>>> ERROR $f <<<<<<<<<<<<<<<<<<<<<<<<"
        fi
   done

   for f in $FILES ; do

        echo "$f"

        f_rootfs=`find /rootfs -name $f`
        if [ -z "$f_rootfs" ] ; then
            echo "$f nema u rootfs"

            for fp in $FILES_FULLPATH ; do
               [ -n "$f" ] && [[ "$fp" =~ "$f" ]]  && echo kopirati $fp && cp -Lv $fp /opt/apps/x11/lib/  # derefrence symlinks
            done
        fi
    done

done
