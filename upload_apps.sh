VER=5.1.6
KERNEL=`cat KERNEL_VERSION`
APP=VirtualBox
./upload_app.sh $APP ${VER}-${KERNEL}

APP=green
VER=1.6.0
#./upload_app.sh $APP $VER

APP=vagrant
VER=1.8.5
#./upload_app.sh $APP $VER

APP=vim
VER=8.0.0
#./upload_app.sh $APP $VER
