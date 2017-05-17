#!/bin/bash

APP=$1
VER=$2


BINTRAY_API_KEY=${BINTRAY_API_KEY:-`cat bintray_api_key`}
BINTRAY_USER=hernad
BINTRAY_REPOS=greenbox

echo "bintray ${APP} check $APP_$VER.tar.xz file exists"
curl -s  -u hernad:$BINTRAY_API_KEY \
      --header "X-Bintray-Override: 1" \
      -X GET https://api.bintray.com/file_version/$BINTRAY_USER/$BINTRAY_REPOS/${APP}_${VER}.tar.xz \
      | grep $VER
