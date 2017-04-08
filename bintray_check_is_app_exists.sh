#!/bin/bash


BINTRAY_USER=hernad
BINTRAY_API_KEY=${BINTRAY_API_KEY:-`cat bintray_api_key`}
BINTRAY_REPOS=greenbox
GREENBOX_VERSION=latest
GREEN_APP=$1
GREEN_APP_VER=$2


app=docker
ver=17.04.0-ce

echo "bintray $GREEN_APP / $GREEN_VER  .tar.xz check file exists"
curl \
      -u hernad:$BINTRAY_API_KEY \
      --header "X-Bintray-Override: 1" \
      -X GET https://api.bintray.com/file_version/$BINTRAY_USER/$BINTRAY_REPOS/${GREEN_APP}_${GREEN_VER}.tar.xz



