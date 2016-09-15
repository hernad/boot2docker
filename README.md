

build image
-----------

     export GREEN_PRODUCTION=vbox # or rack
     ./build.sh greenbox

     => greenbox:1.9.1 docker image


upload_app
----------

     ./upload_app.sh nvim 0.1.1-79


syslinux menu.cfg
--------------------

(podesava se u tc-config)

syslinux varijable:

* nodhcp
* staticip=192.168.169.99 staticiface=eth0   (staticka ip)
* nodockerstart (ne pokretati docker, kreira fajl /opt/boot/init.d/nodockerstart )



tiny core
------------

/usr/local/tce.installed/

=> openssl, openssh

(initialize app - create necessary dirs, generate files etc)
