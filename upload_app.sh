BINTRAY_API_KEY=`cat bintray_api_key`
BINTRAY_REPOS=greenbox

DOCKER_VERSION=`cat DOCKER_VERSION`
#BINTRAY_PACKAGE=VirtualBox
BINTRAY_PACKAGE=$1
#BINTRAY_PACKAGE_VER=5.0.10
BINTRAY_PACKAGE_VER=$2


[ -z "$BINTRAY_PACKAGE" ] && echo package name mora biti navedeno && exit 1
[ -z "$BINTRAY_PACKAGE_VER" ] && echo package version mora biti navedeno && exit 1

FILE=${BINTRAY_PACKAGE}_${BINTRAY_PACKAGE_VER}.tar.gz

if [ ! -f $FILE ] ; then
   docker rm -f greenbox_apps
   docker run --name greenbox_apps greenbox_apps:$DOCKER_VERSION /bin/false
   docker cp greenbox_apps:/opt/apps/${BINTRAY_PACKAGE} ${BINTRAY_PACKAGE} 
   tar cvfz $FILE ${BINTRAY_PACKAGE}
   rm -r -f ${BINTRAY_PACKAGE}
fi

ls -lh $FILE

echo uploading to bintray ...

curl -T $FILE \
      -u hernad:$BINTRAY_API_KEY \
      --header "X-Bintray-Override: 1" \
     https://api.bintray.com/content/hernad/greenbox/$BINTRAY_PACKAGE/$BINTRAY_PACKAGE_VER/$FILE

curl -u hernad:$BINTRAY_API_KEY \
   -X POST https://api.bintray.com/content/hernad/greenbox/$BINTRAY_PACKAGE/$BINTRAY_PACKAGE_VER/publish


