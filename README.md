# greenbox


## build image

     export GREEN_PRODUCTION=vbox # or rack
     ./build.sh greenbox

     => greenbox:1.9.1 docker image


## utilities

    show_curl_downloads.sh
    show_internet_status.sh
    show_zfs_status.sh

    install_green_apps 2 # install second level applications: java, go, perl, atom, code, idea, node

### upload_app

     ./upload_app.sh vim 8.0.5  # upload to bintray.com/hernad/greenbox  vim_8.0.5.tar.xz
     ./upload_apps.sh  # upload all apps to bintray


## syslinux menu.cfg options

syslinux variables:

* nodhcp
* staticip=192.168.169.99 staticiface=eth0   (staticka ip)
* nodockerstart (ne pokretati docker, kreira fajl /opt/boot/init.d/nodockerstart )

(details: /etc/init.d/tc-config)

## tiny core linux notes

/usr/local/tce.installed/

=> openssl, openssh

(initialize app - create necessary dirs, generate files etc)
