VER=5.1.10
APP=VirtualBox
./upload_app.sh $APP ${VER} J  #.tar.xz

APP=docker
VER=`cat DOCKER_VERSION`
rm -rf $APP
#./upload_app.sh $APP $VER  J

APP=green
VER=3.0.2
rm -rf $APP
#./upload_app.sh $APP $VER  J

APP=x11
VER=3.1.0
rm -rf $APP
#./upload_app.sh $APP $VER J

APP=vagrant
VER=1.8.7
rm -rf $APP
#./upload_app.sh $APP $VER J

APP=vim
VER=8.0.62
rm -rf $APP
#./upload_app.sh $APP $VER J

APP=python2
VER=2.7.12
rm -rf $APP
#./upload_app.sh $APP $VER J

APP=ruby
VER=2.3.1
rm -rf $APP
#./upload_app.sh $APP $VER J

APP=perl
VER=5.24.0
rm -rf $APP
#./upload_app.sh $APP $VER J


APP=go
VER=1.7.3
rm -rf $APP
#./upload_app.sh $APP $VER J

APP=node
VER=6.9.1
rm -rf $APP
#./upload_app.sh $APP $VER J

VER=8.112.15
rm -rf $APP
#./upload_app.sh $APP $VER J

APP=atom
VER=1.12.0
rm -rf $APP
#./upload_app.sh $APP $VER J

APP=code
VER=1.7.1
rm -rf $APP
#./upload_app.sh $APP $VER J

APP=idea
VER=2016.5.2
rm -rf $APP
#./upload_app.sh $APP $VER J


APP=aws
VER=1.11.13
rm -rf $APP
#./upload_app.sh $APP $VER J
