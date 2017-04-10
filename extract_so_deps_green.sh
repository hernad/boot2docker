#!/bin/bash


GREEN_LIB=/opt/apps/green/lib/
[ -d $GREEN_LIB ] || mkdir $GREEN_LIB

LDD_CHECK="/opt/apps/green/bin/rsync"


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
               [ -n "$f" ] && [[ "$fp" =~ "$f" ]]  && echo kopirati $fp && cp -Lv $fp $GREEN_LIB  # derefrence symlinks
            done
        fi
    done

done
