BINTRAY_API_KEY=${BINTRAY_API_KEY:-`cat bintray_api_key`}
BINTRAY_REPOS=greenbox
GREENBOX_VERSION=latest
GREEN_APP=$1
GREEN_APP_VER=$2


COMPRESSION=${3:-J} # z - gzip, j-bz2, J-xz

[ -z "$GREEN_APP" ] && echo package name mora biti navedeno && exit 1
[ -z "$GREEN_APP_VER" ] && echo package version mora biti navedeno && exit 1

case $COMPRESSION in
  z)
  EXT="tar.gz"
  ;;
  j)
  EXT="tar.bz2"
  ;;
  J)
  EXT="tar.xz" ;;
esac


FILE=${GREEN_APP}_${GREEN_APP_VER}.${EXT}


if [ ! -f $FILE ] ; then
   case ${GREEN_APP} in
      VirtualBox)
           CT=greenbox
           docker rm -f $CT
           docker run --name $CT $CT:$GREENBOX_VERSION ls /opt/apps && rm -rf VirtualBox
           docker cp $CT:/opt/${GREEN_APP} ${GREEN_APP} || exit 1
           chmod +s VirtualBox/VirtualBox VirtualBox/VBoxHeadless &&\
           find VirtualBox/src -type f -exec rm  {} \; &&\
           find VirtualBox/ExtensionPacks/Oracle_VM_VirtualBox_Extension_Pack/solaris.amd64 -type f -exec rm {} \; &&\
           find VirtualBox/ExtensionPacks/Oracle_VM_VirtualBox_Extension_Pack/darwin.amd64 -type f -exec rm {} \; &&\
           find VirtualBox/ExtensionPacks/Oracle_VM_VirtualBox_Extension_Pack/linux.x86 -type f -exec rm {} \; &&\
           find VirtualBox -name "*.dll" -exec rm {} \; &&\
           find VirtualBox -name "*.pdf" -exec rm {} \; &&\
           find VirtualBox -name "*.o" -exec rm {} \; &&\
           find VirtualBox -name "*.c" -exec rm {} \; || exit 1
           ;;
      ruby|green|docker|vagrant)
           CT=greenbox_app_${GREEN_APP}
           CT_VER=${GREEN_APP_VER}
           docker rm -f $CT
	   echo "source docker image $CT:$CT_VER"
           docker run --name $CT $CT:$CT_VER ls -l /opt/apps/${GREEN_APP}
           docker cp $CT:/opt/apps/${GREEN_APP} ${GREEN_APP} || exit 1
           [ ! -d ${GREEN_APP}/sbin ] ||  mv ${GREEN_APP}/sbin/*  ${GREEN_APP}/bin/ 
           if  [ -d bins/${GREEN_APP} ]
           then
             echo "bins/${GREEN_APP}"
             cp bins/${GREEN_APP}/* ${GREEN_APP}/bin/  
           else
             echo "NO bins/${GREEN_APP}"
           fi
           ;;
 

      *) 
           CT=greenbox_apps
           docker rm -f $CT
           docker run --name $CT $CT:$GREENBOX_VERSION ls -l /opt/apps/${GREEN_APP}
           docker cp $CT:/opt/apps/${GREEN_APP} ${GREEN_APP} || exit 1
           [ ! -d ${GREEN_APP}/sbin ] ||  mv ${GREEN_APP}/sbin/*  ${GREEN_APP}/bin/ 
           if  [ -d bins/${GREEN_APP} ]
           then
             echo "bins/${GREEN_APP}"
             cp bins/${GREEN_APP}/* ${GREEN_APP}/bin/  
           else
             echo "NO bins/${GREEN_APP}"
           fi
           ;;
   esac 
   echo "tar cv${COMPRESSION}f $FILE ${GREEN_APP}"
   tar cv${COMPRESSION}f $FILE ${GREEN_APP}
   rm -r -f ${GREEN_APP}
fi

ls -lh $FILE

echo uploading to bintray ...

curl -s -T $FILE \
      -u hernad:$BINTRAY_API_KEY \
      --header "X-Bintray-Override: 1" \
     https://api.bintray.com/content/hernad/greenbox/$GREEN_APP/$GREEN_APP_VER/$FILE

curl -s -u hernad:$BINTRAY_API_KEY \
   -X POST https://api.bintray.com/content/hernad/greenbox/$GREEN_APP/$GREEN_APP_VER/publish


