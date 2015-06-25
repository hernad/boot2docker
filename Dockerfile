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
# https://www.kernel.org/

ENV KERNEL_MAJOR    4
ENV KERNEL_VERSION_DOWNLOAD  4.1
ENV KERNEL_VERSION  4.1.0

ENV LINUX_KERNEL_SOURCE /usr/src/linux
ENV LINUX_BRAND  greenbox

# Fetch the kernel sources
RUN mkdir -p /usr/src
RUN curl --retry 10 https://www.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR}.x/linux-$KERNEL_VERSION_DOWNLOAD.tar.xz | tar -C / -xJ && \
    mv /linux-$KERNEL_VERSION_DOWNLOAD $LINUX_KERNEL_SOURCE


ENV AUFS_UTIL_GIT    http://git.code.sf.net/p/aufs/aufs-util         
                                                                     
# v4 kernel                                                          
ENV AUFS_VER     aufs4                                               
ENV AUFS_GIT https://github.com/sfjro/aufs4-standalone               
#ENV AUFS_BRANCH  aufs4.0                                            
ENV AUFS_BRANCH  aufs4.x-rcN                                         
ENV AUFS_COMMIT 24c9bc07e475feb2ba10e0471a8ae8f4cf427884          


# Download AUFS and apply patches and files, then remove it
RUN git clone -b $AUFS_BRANCH $AUFS_GIT && \
    cd $AUFS_VER-standalone && \
    git checkout $AUFS_COMMIT && \
    cd $LINUX_KERNEL_SOURCE && \
    cp -r /$AUFS_VER-standalone/Documentation $LINUX_KERNEL_SOURCE && \
    cp -r /$AUFS_VER-standalone/fs $LINUX_KERNEL_SOURCE && \
    cp -r /$AUFS_VER-standalone/include/uapi/linux/aufs_type.h $LINUX_KERNEL_SOURCE/include/uapi/linux/ &&\
    for patch in $AUFS_VER-kbuild $AUFS_VER-base $AUFS_VER-mmap $AUFS_VER-standalone $AUFS_VER-loopback; do \
        patch -p1 < /$AUFS_VER-standalone/$patch.patch; \
    done

COPY kernel_config $LINUX_KERNEL_SOURCE/.config

RUN  sed -i 's/-LOCAL_LINUX_BRAND/'-"$LINUX_BRAND"'/' $LINUX_KERNEL_SOURCE/.config

RUN jobs=$(nproc); \
    cd $LINUX_KERNEL_SOURCE && \
    make -j ${jobs} oldconfig && \
    make -j ${jobs} bzImage && \
    make -j ${jobs} modules

# The post kernel build process

ENV ROOTFS          /rootfs
ENV TCL_REPO_BASE   http://tinycorelinux.net/6.x/x86_64

# Make the ROOTFS
RUN mkdir -p $ROOTFS

# Prepare the build directory (/tmp/iso)
RUN mkdir -p /tmp/iso/boot

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

ENV AUFS_UTIL_BRANCH aufs4.x-rcN

# Make sure the kernel headers are installed for aufs-util, and then build it
RUN cd $LINUX_KERNEL_SOURCE && \
    make INSTALL_HDR_PATH=/tmp/kheaders headers_install && \
    cd / && \
    git clone $AUFS_UTIL_GIT aufs-util && \
    cd /aufs-util && \
    git checkout $AUFS_UTIL_BRANCH && \
    CPPFLAGS="$GCC_M -I/tmp/kheaders/include" CLFAGS=$CPPFLAGS LDFLAGS=$CPPFLAGS make && \
    DESTDIR=$ROOTFS make install && \
    rm -rf /tmp/kheaders

# Prepare the ISO directory with the kernel
RUN cp -v $LINUX_KERNEL_SOURCE/arch/x86_64/boot/bzImage /tmp/iso/boot/vmlinuz64

# Download the rootfs, don't unpack it though:
RUN curl -L -o /tcl_rootfs.gz $TCL_REPO_BASE/release/distribution_files/rootfs64.gz


ENV TCZ_DEPS_0      iptables \
                    iproute2 \
                    openssh openssl-1.0.0 \
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

COPY DOCKER_VERSION $ROOTFS/etc/version
RUN cp -v $ROOTFS/etc/version /tmp/iso/version

# Get the Docker version that matches our boot2docker version
# Note: `docker version` returns non-true when there is no server to ask
RUN curl -L -o $ROOTFS/usr/local/bin/docker https://get.docker.io/builds/Linux/x86_64/docker-$(cat $ROOTFS/etc/version) && \
    chmod +x $ROOTFS/usr/local/bin/docker && \
    { $ROOTFS/usr/local/bin/docker version || true; }

# Get the git versioning info
COPY .git /git/.git
RUN cd /git && \
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) && \
    GITSHA1=$(git rev-parse --short HEAD) && \
    DATE=$(date) && \
    echo "${GIT_BRANCH} : ${GITSHA1} - ${DATE}" > $ROOTFS/etc/boot2docker

# Install Tiny Core Linux rootfs
RUN cd $ROOTFS && zcat /tcl_rootfs.gz | cpio -f -i -H newc -d --no-absolute-filenames

# Copy our custom rootfs
COPY rootfs/rootfs $ROOTFS

# hernad: no hyper-v
# Build the Hyper-V KVP Daemon
# RUN cd $LINUX_KERNEL_SOURCE && \
#    make headers_install INSTALL_HDR_PATH=/usr && \
#    cd /linux-kernel/tools/hv && \
#    sed -i 's/\(^CFLAGS = .*\)/\1 '"$GCC_M"'/' Makefile && \
#    make hv_kvp_daemon && \
#    cp hv_kvp_daemon $ROOTFS/usr/sbin

# These steps can only be run once, so can't be in make_iso.sh (which can be run in chained Dockerfiles)
# see https://github.com/boot2docker/boot2docker/blob/master/doc/BUILD.md


# virtualbox server
# RUN apt-get install gcc g++ bcc iasl xsltproc uuid-dev zlib1g-dev libidl-dev \
#                libsdl1.2-dev libxcursor-dev libasound2-dev libstdc++5 \
#                libhal-dev libpulse-dev libxml2-dev libxslt1-dev \
#                python-dev libqt4-dev qt4-dev-tools libcap-dev \
#                libxmu-dev mesa-common-dev libglu1-mesa-dev \
#                linux-kernel-headers libcurl4-openssl-dev libpam0g-dev \
#                libxrandr-dev libxinerama-dev libqt4-opengl-dev makeself \
#                libdevmapper-dev default-jdk python-central \
#                texlive-latex-base \
#                texlive-latex-extra texlive-latex-recommended \
#                texlive-fonts-extra texlive-fonts-recommended
# On 64-bit Debian-based systems, the following command should install the required additional packages:
#RUN apt-get install ia32-libs libc6-dev-i386 lib32gcc1 gcc-multilib \
#    lib32stdc++6 g++-multilib

ENV VBOX_VER 5.0.0_RC1
ENV VBOX_BUILD 100731
RUN curl -LO http://dlc-cdn.sun.com/virtualbox/$VBOX_VER/VirtualBox-$VBOX_VER-$VBOX_BUILD-Linux_amd64.run
RUN chmod +x *.run
RUN mkdir -p /lib
RUN ln -s $ROOTFS/lib/modules /lib/modules
RUN ./VirtualBox-$VBOX_VER-$VBOX_BUILD-Linux_amd64.run
RUN cp -av /opt/VirtualBox $ROOTFS/opt/

RUN chmod o-w $ROOTFS/opt 
RUN chmod o-w $ROOTFS/opt/VirtualBox
RUN chown root.root $ROOTFS/opt
RUN chown root.root $ROOTFS/opt/VirtualBox
RUN chmod 4755 $ROOTFS/opt/VirtualBox/VBoxHeadless

RUN echo ignoring depmod -a errors
RUN cd /opt/VirtualBox/src/vboxhost && KERN_DIR=$LINUX_KERNEL_SOURCE make MODULE_DIR=$ROOTFS/lib/modules/$KERNEL_VERSION-$LINUX_BRAND/extra/vbox install || true

RUN mkdir /zfs

ENV ZFS_VER 0.6.4.1 
RUN cd /zfs && curl -LO http://archive.zfsonlinux.org/downloads/zfsonlinux/spl/spl-$ZFS_VER.tar.gz
RUN cd /zfs && tar xvf spl-$ZFS_VER.tar.gz && cd spl-$ZFS_VER && ./configure --with-linux=$LINUX_KERNEL_SOURCE && make && make install 

# hernad: zfs build demands librt from debian
RUN cp /lib/x86_64-linux-gnu/librt-2.13.so $ROOTFS/lib/
RUN rm $ROOTFS/lib/librt.so.1
RUN cd $ROOTFS/lib && ln -s librt-2.13.so librt.so.1

ENV ZFS_GIT_BRANCH zfs-0.6.4-release
RUN cd /zfs && git clone https://github.com/zfsonlinux/zfs.git zfs-git && cd /zfs/zfs-git && git checkout $ZFS_GIT_BRANCH 
#RUN cd /zfs && curl -LO http://archive.zfsonlinux.org/downloads/zfsonlinux/zfs/zfs-$ZFS_VER.tar.gz                              
# RUN cd /zfs && tar xvf zfs-$ZFS_VER.tar.gz && cd zfs-$ZFS_VER && ./configure --with-linux=$LINUX_KERNEL_SOURCE && make && DESTDIR=$ROOTFS make install 
RUN cd /zfs/zfs-git && sh autogen.sh && ./configure --with-linux=$LINUX_KERNEL_SOURCE && make && DESTDIR=$ROOTFS make install 
                                                                                                                                
# Install the kernel modules in $ROOTFS                                                                                         
RUN cd $LINUX_KERNEL_SOURCE && \                                                                                                       
    make INSTALL_MOD_PATH=$ROOTFS modules_install firmware_install                                                              

RUN depmod -a -b $ROOTFS $KERNEL_VERSION-$LINUX_BRAND


# Make sure init scripts are executable
RUN find $ROOTFS/etc/rc.d/ $ROOTFS/usr/local/etc/init.d/ -exec chmod +x '{}' ';'

# debug http://unix.stackexchange.com/questions/76490/no-such-file-or-directory-on-an-executable-yet-file-exists-and-ldd-reports-al
# /lib64/ld-linux-x86-64.so.2.
RUN cd $ROOTFS && ln -s lib lib64


# Change MOTD
RUN mv $ROOTFS/usr/local/etc/motd $ROOTFS/etc/motd

# Make sure we have the correct bootsync
RUN mv $ROOTFS/boot*.sh $ROOTFS/opt/ && \
	chmod +x $ROOTFS/opt/*.sh

# Make sure we have the correct shutdown
RUN mv $ROOTFS/shutdown.sh $ROOTFS/opt/shutdown.sh && \
	chmod +x $ROOTFS/opt/shutdown.sh

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

# crontab
COPY rootfs/crontab $ROOTFS/var/spool/cron/crontabs/root

# set ttyS0 115200
COPY rootfs/inittab $ROOTFS/etc/inittab
COPY rootfs/securetty $ROOTFS/etc/securetty
COPY rootfs/tc-config $ROOTFS/etc/init.d/tc-config

RUN  mkdir -p $ROOTFS/usr/local/etc/ssh
COPY rootfs/sshd_config $ROOTFS/usr/local/etc/ssh/sshd_config

# Copy boot params
COPY rootfs/isolinux /tmp/iso/boot/isolinux
COPY rootfs/make_iso.sh /

#RUN git clone https://github.com/hishamhm/htop.git
#RUN cd /htop && ./autogen.sh && ./configure --prefix=$ROOTFS --enable-cgroup && make  && make install

#RUN cp /usr/lib/x86_64-linux-gnu/libpanelw.so.5.9 $ROOTFS/usr/local/lib/libpanelw.so.5
#RUN cp /usr/lib/x86_64-linux-gnu/libmenuw.so.5.9 $ROOTFS/usr/local/lib/libmenuw.so.5
#RUN cp /usr/lib/x86_64-linux-gnu/libformw.so.5.9 $ROOTFS/usr/local/lib/libformw.so.5
#RUN cp /lib/x86_64-linux-gnu/libncursesw.so.5.9 $ROOTFS/usr/local/lib/libncursesw.so.5
#RUN cp /lib/x86_64-linux-gnu/libncurses.so.5.9 $ROOTFS/usr/local/lib/libncurses.so.5


#RUN cp /lib/x86_64-linux-gnu/libpthread-2.13.so $ROOTFS/lib/libpthread.so.0

RUN echo "--------- tmux & libevent install ------------"
RUN curl -L -O  https://sourceforge.net/projects/levent/files/libevent/libevent-2.0/libevent-2.0.22-stable.tar.gz
RUN tar xvf libevent-2.0.22-stable.tar.gz
RUN cd /libevent-2.0.22-stable && sh autogen.sh && ./configure && make install && cp .libs/*so* $ROOTFS/usr/local/lib/

RUN git clone https://github.com/ThomasAdam/tmux.git tmux
RUN cd tmux && sh autogen.sh && ./configure && make && cp tmux $ROOTFS/usr/local/bin/tmux && chmod +x $ROOTFS/usr/local/bin/tmux
RUN cp /usr/lib/x86_64-linux-gnu/libtinfo.so $ROOTFS/usr/local/lib/libtinfo.so.5

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


ENV TCZ_DEPS_1      python fuse libffi  samba samba-libs bind-utilities openssl-1.0.0 libxml2

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

RUN curl -LO https://download.samba.org/pub/rsync/src/rsync-3.1.1.tar.gz                
RUN tar xvf rsync-3.1.1.tar.gz 
RUN cd /rsync-3.1.1 && ./configure && make && /usr/bin/install -c  -m 755 rsync $ROOTFS/usr/local/bin
                                                                                      

RUN curl -LO https://www.openfabrics.org/downloads/qperf/qperf-0.4.9.tar.gz
RUN tar xvf qperf-0.4.9.tar.gz
RUN cd /qperf-0.4.9 && sh autogen.sh && ./configure && make && /usr/bin/install -c src/qperf $ROOTFS/usr/local/bin


RUN curl -LO https://github.com/zfsonlinux/zfs-auto-snapshot/archive/master.zip
RUN unzip master.zip
RUN cd zfs-auto-snapshot-master && /usr/bin/install src/zfs-auto-snapshot.sh $ROOTFS/usr/local/sbin/zfs-auto-snapshot

ENV VAGRANT_VER 1.7.2
RUN curl -k -LO https://dl.bintray.com/mitchellh/vagrant/vagrant_${VAGRANT_VER}_x86_64.deb
RUN dpkg -i vagrant_${VAGRANT_VER}_x86_64.deb

RUN /make_iso.sh

CMD ["cat", "boot2docker.iso"]
