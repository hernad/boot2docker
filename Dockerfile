FROM debian:wheezy
MAINTAINER Ernad Husremovic "hernad@bring.out.ba"

RUN apt-get update && apt-get -y install  unzip \
                        xz-utils \
                        curl \
                        bc \
                        git \
                        build-essential \
                        cpio \
                        gcc-multilib libc6-i386 libc6-dev-i386 \
                        kmod \
                        squashfs-tools \
                        genisoimage \
                        xorriso \
                        syslinux \
                        automake \
                        pkg-config \
                        uuid-dev \
                        libncursesw5-dev libncurses-dev

ENV GCC_M -m64
# https://www.kernel.org/pub/linux/kernel/v4.x/

ENV KERNEL_MAJOR=4 KERNEL_VERSION_DOWNLOAD=4.3.3  KERNEL_VERSION=4.3.3

ENV LINUX_BRAND=greenbox LINUX_KERNEL_SOURCE=/usr/src/linux


# Fetch the kernel sources
RUN mkdir -p /usr/src && \
    curl --retry 10 https://www.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR}.x/linux-$KERNEL_VERSION_DOWNLOAD.tar.xz | tar -C / -xJ && \
    mv /linux-$KERNEL_VERSION_DOWNLOAD $LINUX_KERNEL_SOURCE

#ENV AUFS_UTIL_GIT    http://git.code.sf.net/p/aufs/aufs-util         
                                                                     
# v4 kernel                                                          
#ENV AUFS_VER aufs4                                               
#ENV AUFS_GIT https://github.com/sfjro/aufs4-standalone               

#ENV AUFS_BRANCH  aufs4.1
#ENV AUFS_UTIL_BRANCH aufs4.0

# Download AUFS and apply patches and files, then remove it
#RUN git clone -b $AUFS_BRANCH $AUFS_GIT && \
#    cd $AUFS_VER-standalone && \
#    cd $LINUX_KERNEL_SOURCE && \
#    cp -r /$AUFS_VER-standalone/Documentation $LINUX_KERNEL_SOURCE && \
#    cp -r /$AUFS_VER-standalone/fs $LINUX_KERNEL_SOURCE && \
#    cp -r /$AUFS_VER-standalone/include/uapi/linux/aufs_type.h $LINUX_KERNEL_SOURCE/include/uapi/linux/ &&\
#    for patch in $AUFS_VER-kbuild $AUFS_VER-base $AUFS_VER-mmap $AUFS_VER-standalone $AUFS_VER-loopback; do \
#        patch -p1 < /$AUFS_VER-standalone/$patch.patch; \
#    done


COPY kernel_config $LINUX_KERNEL_SOURCE/.config

RUN  sed -i 's/-LOCAL_LINUX_BRAND/'-"$LINUX_BRAND"'/' $LINUX_KERNEL_SOURCE/.config

RUN jobs=$(nproc); \
    cd $LINUX_KERNEL_SOURCE && \
    make -j ${jobs} oldconfig && \
    make -j ${jobs} bzImage && \
    make -j ${jobs} modules

# The post kernel build process

ENV ROOTFS=/rootfs TCL_REPO_BASE=http://tinycorelinux.net/6.x/x86_64

# Make the ROOTFS
# Prepare the build directory (/tmp/iso)

RUN mkdir -p $ROOTFS &&\ 
    mkdir -p /tmp/iso/boot

# Install the kernel modules in $ROOTFS
RUN cd $LINUX_KERNEL_SOURCE && \
    make INSTALL_MOD_PATH=$ROOTFS modules_install firmware_install

# Remove useless kernel modules, based on unclejack/debian2docker
RUN cd $ROOTFS/lib/modules && \
    rm -rf ./*/kernel/sound/* && \
    rm -rf ./*/kernel/drivers/gpu/* && \
    rm -rf ./*/kernel/drivers/infiniband/* && \
    rm -rf ./*/kernel/drivers/isdn/* && \
    rm -rf ./*/kernel/drivers/media/* && \
    rm -rf ./*/kernel/drivers/staging/lustre/* && \
    rm -rf ./*/kernel/drivers/staging/comedi/* && \
    rm -rf ./*/kernel/fs/ocfs2/* && \
    rm -rf ./*/kernel/net/bluetooth/* && \
    rm -rf ./*/kernel/net/mac80211/* && \
    rm -rf ./*/kernel/net/wireless/*

# Install libcap
RUN curl -L http://http.debian.net/debian/pool/main/libc/libcap2/libcap2_2.22.orig.tar.gz | tar -C / -xz && \
    cd /libcap-2.22 && \
    sed -i 's/LIBATTR := yes/LIBATTR := no/' Make.Rules && \
    sed -i 's/\(^CFLAGS := .*\)/\1 '"$GCC_M"'/' Make.Rules && \
    make && \
    mkdir -p output && \
    make prefix=`pwd`/output install && \
    mkdir -p $ROOTFS/usr/local/lib && \
    cp -av `pwd`/output/lib64/* $ROOTFS/usr/local/lib


# Make sure the kernel headers are installed for aufs-util, and then build it
RUN cd $LINUX_KERNEL_SOURCE && \
    make INSTALL_HDR_PATH=/tmp/kheaders headers_install 

#RUN cd / && \
#    git clone $AUFS_UTIL_GIT aufs-util && \
#    cd /aufs-util && \
#    git checkout $AUFS_UTIL_BRANCH && \
#    CPPFLAGS="$GCC_M -I/tmp/kheaders/include" CLFAGS=$CPPFLAGS LDFLAGS=$CPPFLAGS make && \
#    DESTDIR=$ROOTFS make install && \
#    rm -rf /tmp/kheaders

# Prepare the ISO directory with the kernel
RUN cp -v $LINUX_KERNEL_SOURCE/arch/x86_64/boot/bzImage /tmp/iso/boot/vmlinuz64

# Download the rootfs, don't unpack it though:
RUN curl -L -o /tcl_rootfs.gz $TCL_REPO_BASE/release/distribution_files/rootfs64.gz


ENV TCZ_DEPS_0      iptables \
                    iproute2 \
                    openssh openssl \
                    tar e2fsprogs \
                    gcc_libs \
                    acpid \
                    xz liblzma \
                    git patch expat2 pcre libgpg-error libgcrypt libssh2 \
                    nfs-utils tcp_wrappers portmap rpcbind libtirpc \
                    curl ntpclient \
                    bash readline htop ncurses ncurses-utils ncurses-terminfo \
                    strace glib2 libtirpc 

# Install the base tiny linux dependencies
RUN for dep in $TCZ_DEPS_0 ; do \
        echo "Download $TCL_REPO_BASE/tcz/$dep.tcz"  && \
        curl -L -o /tmp/$dep.tcz $TCL_REPO_BASE/tcz/$dep.tcz && \
        if [ ! -s /tmp/$dep.tcz ] ; then \
          echo "$TCL_REPO_BASE/tcz/$dep.tcz size is zero 0 - error !" && \
          exit 1 ;\
        else \
          unsquashfs -i -f -d $ROOTFS /tmp/$dep.tcz && \
          rm -f /tmp/$dep.tcz ;\
          if [ "$?" != "0" ] ; then exit 1 ; fi ;\
        fi ;\
    done

# get generate_cert
RUN curl -L -o $ROOTFS/usr/local/bin/generate_cert https://github.com/SvenDowideit/generate_cert/releases/download/0.1/generate_cert-0.1-linux-386/ && \
    chmod +x $ROOTFS/usr/local/bin/generate_cert

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y libfuse2 libtool autoconf \
                                                                         libglib2.0-dev libdumbnet-dev:i386 \
                                                                         libdumbnet1:i386 libfuse2:i386 libfuse-dev \
                                                                         libglib2.0-0:i386 libtirpc-dev libtirpc1:i386

# https://github.com/docker/docker/releases

COPY DOCKER_VERSION $ROOTFS/etc/version
RUN cp -v $ROOTFS/etc/version /tmp/iso/version

# Get the Docker version that matches our greenbox version
# Note: `docker version` returns non-true when there is no server to ask
RUN curl -L -o $ROOTFS/usr/local/bin/docker https://get.docker.io/builds/Linux/x86_64/docker-$(cat $ROOTFS/etc/version) && \
    chmod +x $ROOTFS/usr/local/bin/docker && \
    { $ROOTFS/usr/local/bin/docker version || true; }

# Install Tiny Core Linux rootfs
RUN cd $ROOTFS && zcat /tcl_rootfs.gz | cpio -f -i -H newc -d --no-absolute-filenames


# http://download.virtualbox.org/virtualbox/5.0.10/

ENV VBOX_VER=5.0.10 VBOX_BUILD=104061

RUN curl -LO http://dlc-cdn.sun.com/virtualbox/$VBOX_VER/VirtualBox-$VBOX_VER-$VBOX_BUILD-Linux_amd64.run &&\
    chmod +x *.run ;\
    mkdir -p /lib ;\
    ln -s $ROOTFS/lib/modules /lib/modules ;\
    ./VirtualBox-$VBOX_VER-$VBOX_BUILD-Linux_amd64.run ;\
    cp -av /opt/VirtualBox $ROOTFS/opt/

RUN chmod o-w $ROOTFS/opt ;\ 
    chmod o-w $ROOTFS/opt/VirtualBox ;\
    chown root.root $ROOTFS/opt ;\
    chown root.root $ROOTFS/opt/VirtualBox ;\
    chmod 4755 $ROOTFS/opt/VirtualBox/VBoxHeadless

#RUN echo ignoring depmod -a errors
RUN cd /opt/VirtualBox/src/vboxhost && KERN_DIR=$LINUX_KERNEL_SOURCE make MODULE_DIR=$ROOTFS/lib/modules/$KERNEL_VERSION-$LINUX_BRAND/extra/vbox install || true

RUN mkdir /zfs

# http://zfsonlinux.org/

ENV ZFS_VER 0.6.5.3
RUN cd /zfs && curl -LO http://archive.zfsonlinux.org/downloads/zfsonlinux/spl/spl-$ZFS_VER.tar.gz &&\
    cd /zfs && tar xf spl-$ZFS_VER.tar.gz && cd spl-$ZFS_VER &&\
    ./configure --with-linux=$LINUX_KERNEL_SOURCE && make && make install 

# hernad: zfs build demands librt from debian
RUN cp /lib/x86_64-linux-gnu/librt-2.13.so $ROOTFS/lib/ &&\
    rm $ROOTFS/lib/librt.so.1 &&\
    cd $ROOTFS/lib && ln -s librt-2.13.so librt.so.1

# build zfs from git
# ENV ZFS_GIT_BRANCH zfs-0.6.4-release
# RUN cd /zfs && git clone https://github.com/zfsonlinux/zfs.git zfs-git && cd /zfs/zfs-git && git checkout $ZFS_GIT_BRANCH 
# RUN cd /zfs/zfs-git && sh autogen.sh && ./configure --with-linux=$LINUX_KERNEL_SOURCE && make && DESTDIR=$ROOTFS make install 

# build zfs from tar
RUN cd /zfs && curl -LO http://archive.zfsonlinux.org/downloads/zfsonlinux/zfs/zfs-$ZFS_VER.tar.gz &&\
    cd /zfs && tar xf zfs-$ZFS_VER.tar.gz && cd zfs-$ZFS_VER &&\
    ./configure --with-linux=$LINUX_KERNEL_SOURCE && make &&\
    DESTDIR=$ROOTFS make install
                                                                                                                                
# Install the kernel modules in $ROOTFS                                                                                         
RUN cd $LINUX_KERNEL_SOURCE && \                                                                                                       
    make INSTALL_MOD_PATH=$ROOTFS modules_install firmware_install

RUN depmod -a -b $ROOTFS $KERNEL_VERSION-$LINUX_BRAND


# debug http://unix.stackexchange.com/questions/76490/no-such-file-or-directory-on-an-executable-yet-file-exists-and-ldd-reports-al
# /lib64/ld-linux-x86-64.so.2.
RUN cd $ROOTFS && ln -s lib lib64

# hernad: no autologin serial console
# Add serial console
# RUN echo "#!/bin/sh" > $ROOTFS/usr/local/bin/autologin && \
#	echo "/bin/login -f docker" >> $ROOTFS/usr/local/bin/autologin && \
#	chmod 755 $ROOTFS/usr/local/bin/autologin && \
#	echo 'ttyS0:2345:respawn:/sbin/getty -l /usr/local/bin/autologin 9600 ttyS0 vt100' >> $ROOTFS/etc/inittab && \
#	echo 'ttyS1:2345:respawn:/sbin/getty -l /usr/local/bin/autologin 9600 ttyS1 vt100' >> $ROOTFS/etc/inittab

# fix "su -"
RUN echo root > $ROOTFS/etc/sysconfig/superuser

RUN rm -r -f $ROOTFS/opt/VirtualBox

ENV TCZ_DEPS_X    Xorg-7.7-bin libpng libXau libXext libxcb libXdmcp libX11 libICE libXt libSM libXmu aterm \
                  libXcursor libXrender libXinerama libGL libXdamage libXfixes libXxf86vm libxshmfence libdrm \
                  libXfont freetype harfbuzz fontconfig Xorg-fonts

RUN for dep in $TCZ_DEPS_X ; do \
        echo "Download $TCL_REPO_BASE/tcz/$dep.tcz"  && \
        curl -L -o /tmp/$dep.tcz $TCL_REPO_BASE/tcz/$dep.tcz && \
        if [ ! -s /tmp/$dep.tcz ] ; then \
          echo "$TCL_REPO_BASE/tcz/$dep.tcz size is zero 0 - error !" && \
          exit 1 ;\
        else \
          unsquashfs -i -f -d $ROOTFS /tmp/$dep.tcz && \
          rm -f /tmp/$dep.tcz ;\
          if [ "$?" != "0" ] ; then exit 1 ; fi ;\
        fi ;\
    done


ENV TCZ_DEPS_1  cifs-utils fuse libffi bind-utilities

RUN for dep in $TCZ_DEPS_1 ; do \
        echo "Download $TCL_REPO_BASE/tcz/$dep.tcz"  && \
        curl -L -o /tmp/$dep.tcz $TCL_REPO_BASE/tcz/$dep.tcz && \
        if [ ! -s /tmp/$dep.tcz ] ; then \
          echo "$TCL_REPO_BASE/tcz/$dep.tcz size is zero 0 - error !" && \
          exit 1 ;\
        else \
          unsquashfs -i -f -d $ROOTFS /tmp/$dep.tcz && \
          rm -f /tmp/$dep.tcz ;\
          if [ "$?" != "0" ] ; then exit 1 ; fi ;\
        fi ;\
    done

# =============================================================================================

COPY rootfs/rootfs $ROOTFS

# crontab                             
COPY rootfs/crontab $ROOTFS/var/spool/cron/crontabs/root                                                                   
                                                                                                                                
# set ttyS0 115200                                                              
COPY rootfs/inittab $ROOTFS/etc/inittab             
COPY rootfs/securetty $ROOTFS/etc/securetty                                                                  
COPY rootfs/tc-config $ROOTFS/etc/init.d/tc-config                                                             
                                                                  
RUN  mkdir -p $ROOTFS/usr/local/etc/ssh                      
COPY rootfs/sshd_config $ROOTFS/usr/local/etc/ssh/sshd_config
COPY rootfs/environment $ROOTFS/etc/environment
COPY rootfs/sshrc $ROOTFS/usr/local/etc/ssh/sshrc


# Copy boot params                                                                                      
COPY rootfs/isolinux /tmp/iso/boot/isolinux                                                             
COPY rootfs/make_iso.sh /

# Make sure init scripts are executable
RUN find $ROOTFS/etc/rc.d/ $ROOTFS/usr/local/etc/init.d/ -exec chmod +x '{}' ';'

# Get the git versioning info
COPY .git /git/.git  
RUN cd /git && \
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) && \
    GITSHA1=$(git rev-parse --short HEAD) && \
    DATE=$(date) && \
    echo "${GIT_BRANCH} : ${GITSHA1} - ${DATE}" > $ROOTFS/etc/greenbox
  

# Change MOTD                                                                                                                   
RUN mv $ROOTFS/usr/local/etc/motd $ROOTFS/etc/motd                                                                              
                                                                                                                                
# Make sure we have the correct bootsync                                                                                        
RUN mv $ROOTFS/boot*.sh $ROOTFS/opt/ && \                                                                                       
        chmod +x $ROOTFS/opt/*.sh                                                                                               
                                                                                                                                
# Make sure we have the correct shutdown                                                                                        
RUN mv $ROOTFS/shutdown.sh $ROOTFS/opt/shutdown.sh && \                                                                         
        chmod +x $ROOTFS/opt/shutdown.sh  


WORKDIR /

# remove git-cvsserver, gitk
# move zfs utilites zdb, zed, ztest to /opt/apps/green

RUN cd $ROOTFS/usr/local/bin && rm git-cvsserver gitk &&\
    cd $ROOTFS/usr/local/share &&\
    rm -r -f git-gui gitk gitweb &&\
    rm -r -f applications pixmaps &&\
    rm -r -f $ROOTFS/usr/local/tce-installed &&\
    rm -r -f $ROOTFS/usr/local/sbin/tce* &&\
    ( [ -d /opt/apps/green/sbin ] || mkdir -p /opt/apps/green/sbin ) &&\
    cd $ROOTFS/usr/local/sbin && mv zdb zed ztest /opt/apps/green/sbin


#RUN cd $ROOTFS/usr/local
#ENV TCZ_DEPS_X    Xorg-7.7-bin libpng libXau libXext libxcb libXdmcp libX11 libICE libXt libSM libXmu aterm \
#                  libXcursor libXrender libXinerama libGL libXdamage libXfixes libXxf86vm libxshmfence libdrm \
#                  libXfont freetype harfbuzz fontconfig Xorg-fonts


RUN cd / && curl -LO $TCL_REPO_BASE/tcz/Xorg-7.7-bin.tcz.list &&\
   ( [ -d /opt/apps/x11/bin ] || mkdir -p /opt/apps/x11/bin ) &&\
   ( [ -d /opt/apps/x11/lib ] || mkdir -p /opt/apps/x11/lib ) &&\
   while read FILE ; do case $FILE in \
                          *\/bin\/*) mv $ROOTFS/$FILE /opt/apps/x11/bin ;; \
                          *\/lib\/*) mv $ROOTFS/$FILE /opt/apps/x11/lib ;; \
		   esac ; done < Xorg-7.7-bin.tcz.list &&\
   cd $ROOTFS/usr/local/lib && \
   mv libpng* libXau* libxcb* libXdmcp* libX11* libICE* libXt* libSM* libXmu* libXcursor* libdrm* libXfont* \
         /opt/apps/x11/lib


RUN /make_iso.sh

CMD ["cat", "greenbox.iso"]
