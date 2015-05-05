FROM debian:wheezy
MAINTAINER Steeve Morin "hernad@bring.out.ba"

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
                        p7zip-full \
                        uuid-dev \
                        libncursesw5-dev libncurses-dev

ENV GCC_M -m64
# https://www.kernel.org/
# ENV KERNEL_VERSION  3.18.12
ENV KERNEL_VERSION  3.19.6

ENV LINUX_KERNEL /usr/src/linux


ENV AUFS_VER        aufs3
#ENV AUFS_BRANCH     aufs3.18.1+
#ENV AUFS_COMMIT     863c3b76303a1ebea5b6a5b1b014715ac416f913
ENV AUFS_BRANCH     aufs3.19
ENV AUFS_COMMIT     cb95a08bdd37434ca8ba3a92679a5f33c48d7524
# http://sourceforge.net/p/aufs/aufs3-standalone/ref/master/branches/
ENV AUFS_GIT        http://git.code.sf.net/p/aufs/aufs3-standalone

ENV AUFS_UTIL_BRANCH aufs3.9 
ENV AUFS_UTIL_GIT    http://git.code.sf.net/p/aufs/aufs-util
 
# v4 kernel
# ENV AUFS_VER     aufs4
# ENV AUFS_GIT https://github.com/sfjro/aufs4-standalone
# ENV AUFS_BRANCH  aufs4.0
# ENV AUFS_COMMIT  170c7ace871c84ba70646f642003edf2d9162144


# Fetch the kernel sources
RUN mkdir -p /usr/src
RUN curl --retry 10 https://www.kernel.org/pub/linux/kernel/v3.x/linux-$KERNEL_VERSION.tar.xz | tar -C / -xJ && \
    mv /linux-$KERNEL_VERSION $LINUX_KERNEL

# Download AUFS and apply patches and files, then remove it
RUN git clone -b $AUFS_BRANCH $AUFS_GIT/$AUFS_VER-standalone && \
    cd $AUFS_VER-standalone && \
    git checkout $AUFS_COMMIT && \
    cd $LINUX_KERNEL && \
    cp -r /$AUFS_VER-standalone/Documentation $LINUX_KERNEL && \
    cp -r /$AUFS_VER-standalone/fs $LINUX_KERNEL && \
    cp -r /$AUFS_VER-standalone/include/uapi/linux/aufs_type.h $LINUX_KERNEL/include/uapi/linux/ &&\
    for patch in $AUFS_VER-kbuild $AUFS_VER-base $AUFS_VER-mmap $AUFS_VER-standalone $AUFS_VER-loopback; do \
        patch -p1 < /$AUFS_VER-standalone/$patch.patch; \
    done

COPY kernel_config $LINUX_KERNEL/.config

RUN jobs=$(nproc); \
    cd $LINUX_KERNEL && \
    make -j ${jobs} oldconfig && \
    make -j ${jobs} bzImage && \
    make -j ${jobs} modules

# The post kernel build process

ENV ROOTFS          /rootfs
ENV TCL_REPO_BASE   http://tinycorelinux.net/6.x/x86_64
ENV TCZ_DEPS        iptables \
                    iproute2 \
                    openssh openssl-1.0.0 \
                    tar e2fsprogs \
                    gcc_libs \
                    acpid \
                    xz liblzma \
                    git patch expat2 libiconv libidn libgpg-error libgcrypt libssh2 \
                    nfs-utils tcp_wrappers portmap rpcbind libtirpc \
                    curl ntpclient \
                    strace procps glib2 libtirpc libffi fuse \
                    samba python \
                    Xorg-7.7-bin Xorg-fonts  aterm libXext libX11 libxcb libXaw libXmu libXext libX11 libxcb libXt libXpm libXcomposite libXcursor libXrender libXfixes libXdamage libXfont freetype


# Make the ROOTFS
RUN mkdir -p $ROOTFS

# Prepare the build directory (/tmp/iso)
RUN mkdir -p /tmp/iso/boot

# Install the kernel modules in $ROOTFS
RUN cd $LINUX_KERNEL && \
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
RUN cd $LINUX_KERNEL && \
    make INSTALL_HDR_PATH=/tmp/kheaders headers_install && \
    cd / && \
    git clone $AUFS_UTIL_GIT aufs-util && \
    cd /aufs-util && \
    git checkout $AUFS_UTIL_BRANCH && \
    CPPFLAGS="$GCC_M -I/tmp/kheaders/include" CLFAGS=$CPPFLAGS LDFLAGS=$CPPFLAGS make && \
    DESTDIR=$ROOTFS make install && \
    rm -rf /tmp/kheaders

# Prepare the ISO directory with the kernel
RUN cp -v $LINUX_KERNEL/arch/x86_64/boot/bzImage /tmp/iso/boot/vmlinuz64

# Download the rootfs, don't unpack it though:
RUN curl -L -o /tcl_rootfs.gz $TCL_REPO_BASE/release/distribution_files/rootfs64.gz

# Install the TCZ dependencies
RUN for dep in $TCZ_DEPS; do \
    echo "Download $TCL_REPO_BASE/tcz/$dep.tcz" &&\
        curl -L -o /tmp/$dep.tcz $TCL_REPO_BASE/tcz/$dep.tcz && \
        unsquashfs -f -d $ROOTFS /tmp/$dep.tcz && \
        rm -f /tmp/$dep.tcz ;\
    done

# get generate_cert
RUN curl -L -o $ROOTFS/usr/local/bin/generate_cert https://github.com/SvenDowideit/generate_cert/releases/download/0.1/generate_cert-0.1-linux-386/ && \
    chmod +x $ROOTFS/usr/local/bin/generate_cert

# hernad: no vbox guest additions
# Build VBox guest additions
# For future reference, we have to use x86 versions of several of these bits because TCL doesn't support ELFCLASS64
# (... and we can't use VBoxControl or VBoxService at all because of this)
#ENV VBOX_VERSION 4.3.26
#RUN mkdir -p /vboxguest && \
#    cd /vboxguest && \
#    \
#    curl -L -o vboxguest.iso http://download.virtualbox.org/virtualbox/${VBOX_VERSION}/VBoxGuestAdditions_${VBOX_VERSION}.iso && \
#    7z x vboxguest.iso -ir'!VBoxLinuxAdditions.run' && \
#    rm vboxguest.iso && \
#    \
#    sh VBoxLinuxAdditions.run --noexec --target . && \
#    mkdir amd64 && tar -C amd64 -xjf VBoxGuestAdditions-amd64.tar.bz2 && \
#    mkdir x86 && tar -C x86 -xjf VBoxGuestAdditions-x86.tar.bz2 && \
#    rm VBoxGuestAdditions*.tar.bz2 && \
#    \
#    KERN_DIR=$LINUX_KERNEL make -C amd64/src/vboxguest-${VBOX_VERSION} && \
#    cp amd64/src/vboxguest-${VBOX_VERSION}/*.ko $ROOTFS/lib/modules/$KERNEL_VERSION-tinycore64/ && \
#    \
#    mkdir -p $ROOTFS/sbin && \
#    cp x86/lib/VBoxGuestAdditions/mount.vboxsf $ROOTFS/sbin/

# Build VMware Tools
# ENV OVT_VERSION 9.4.6-1770165

# Download and prepare ovt source
# RUN mkdir -p /vmtoolsd/open-vm-tools \
#    && curl -L http://downloads.sourceforge.net/open-vm-tools/open-vm-tools-$OVT_VERSION.tar.gz \
#        | tar -xzC /vmtoolsd/open-vm-tools --strip-components 1

# Apply patches to make open-vm-tools compile with a recent 3.18.x kernel and
# a network script that knows how to plumb/unplumb nics on a busybox system,
# this will be removed once a new ovt version is released.
#RUN cd /vmtoolsd && \
#    curl -L -o open-vm-tools-3.x.x-patches.patch https://gist.github.com/frapposelli/5506651fa6f3d25d5760/raw/475f8fb2193549c10a477d506de40639b04fa2a7/open-vm-tools-3.x.x-patches.patch &&\
#    patch -p1 < open-vm-tools-3.x.x-patches.patch && rm open-vm-tools-3.x.x-patches.patch

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y libfuse2 libtool autoconf \
                                                                         libglib2.0-dev libdumbnet-dev:i386 \
                                                                         libdumbnet1:i386 libfuse2:i386 libfuse-dev \
                                                                         libglib2.0-0:i386 libtirpc-dev libtirpc1:i386
# hernad: no i386
# Horrible Hack
#RUN ln -s /lib/i386-linux-gnu/libglib-2.0.so.0.3200.4 /lib/i386-linux-gnu/libglib-2.0.so &&\
#    ln -s /lib/i386-linux-gnu/libtirpc.so.1.0.10 /lib/i386-linux-gnu/libtirpc.so &&\
#    ln -s /usr/lib/i386-linux-gnu/libgthread-2.0.so.0 /usr/lib/i386-linux-gnu/libgthread-2.0.so &&\
#    ln -s /usr/lib/i386-linux-gnu/libgmodule-2.0.so.0 /usr/lib/i386-linux-gnu/libgmodule-2.0.so &&\
#    ln -s /usr/lib/i386-linux-gnu/libgobject-2.0.so.0 /usr/lib/i386-linux-gnu/libgobject-2.0.so &&\
#    ln -s /lib/i386-linux-gnu/libfuse.so.2 /lib/i386-linux-gnu/libfuse.so

# hernad: no vmware
# Compile open-vm-tools
#RUN cd /vmtoolsd/open-vm-tools && autoreconf -i &&\
#    CC="gcc $GCC_M" CXX="g++ $GCC_M" ./configure --host=i486-pc-linux-gnu --build=i486-pc-linux-gnu \
#                --without-kernel-modules --without-pam --without-procps --without-x --without-icu &&\
#    make CC="gcc $GCC_M" CXX="g++ $GCC_M" LIBS="-ltirpc" CFLAGS="-Wno-implicit-function-declaration" &&\
#    make DESTDIR=$ROOTFS install

# Download and compile libdnet as open-vm-tools rely on it.
# ENV LIBDNET libdnet-1.11

#RUN mkdir -p /vmtoolsd/${LIBDNET} &&\
#    curl -L http://sourceforge.net/projects/libdnet/files/libdnet/${LIBDNET}/${LIBDNET}.tar.gz \
#        | tar -xzC /vmtoolsd/${LIBDNET} --strip-components 1 &&\
#    cd /vmtoolsd/${LIBDNET} && ./configure --build=i486-pc-linux-gnu &&\
#    make CC="gcc $GCC_M" CXX="g++ $GCC_M" &&\
#    make install && make DESTDIR=$ROOTFS install

# RUN cd $ROOTFS && cd usr/local/lib && ln -s libdnet.1 libdumbnet.so.1

# Make sure that all the modules we might have added are recognized (especially VBox guest additions)
# RUN depmod -a -b $ROOTFS $KERNEL_VERSION-tinycore64

COPY VERSION $ROOTFS/etc/version
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
# RUN cd $LINUX_KERNEL && \
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

RUN curl -LO http://dlc-cdn.sun.com/virtualbox/5.0.0_BETA2/VirtualBox-5.0.0_BETA2-99573-Linux_amd64.run
RUN chmod +x *.run
RUN mkdir -p /lib
RUN ln -s $ROOTFS/lib/modules /lib/modules
RUN ./VirtualBox-5.0.0_BETA2-99573-Linux_amd64.run
RUN cp -av /opt/VirtualBox $ROOTFS/opt/


RUN chmod o-w $ROOTFS/opt 
RUN chmod o-w $ROOTFS/opt/VirtualBox
RUN chown root.root $ROOTFS/opt
RUN chown root.root $ROOTFS/opt/VirtualBox
RUN chmod 4755 $ROOTFS/opt/VirtualBox/VBoxHeadless

RUN cd /opt/VirtualBox/src/vboxhost && make && make install

# Install the kernel modules in $ROOTFS                                                                                         
RUN cd $LINUX_KERNEL && \                                                                                                       
    make INSTALL_MOD_PATH=$ROOTFS modules_install firmware_install

RUN mkdir /zfs

ENV ZFS_VER 0.6.4 
RUN cd /zfs && curl -LO http://archive.zfsonlinux.org/downloads/zfsonlinux/spl/spl-$ZFS_VER.tar.gz
#RUN cd $LINUX_KERNEL && make modules
RUN cd /zfs && tar xvf spl-$ZFS_VER.tar.gz && cd spl-$ZFS_VER && ./configure && make && make install 

# hernad: zfs build demands librt from debian
RUN cp /lib/x86_64-linux-gnu/librt-2.13.so $ROOTFS/lib/
RUN rm $ROOTFS/lib/librt.so.1
RUN cd $ROOTFS/lib && ln -s librt-2.13.so librt.so.1
RUN cd /zfs && curl -LO http://archive.zfsonlinux.org/downloads/zfsonlinux/zfs/zfs-$ZFS_VER.tar.gz                              
RUN cd /zfs && tar xvf zfs-$ZFS_VER.tar.gz && cd zfs-$ZFS_VER && ./configure && make && DESTDIR=$ROOTFS make install 
                                                                                                                                
# Install the kernel modules in $ROOTFS                                                                                         
RUN cd $LINUX_KERNEL && \                                                                                                       
    make INSTALL_MOD_PATH=$ROOTFS modules_install firmware_install                                                              

# Make sure that all the modules we might have added are recognized (especially VBox guest additions)
RUN depmod -a -b $ROOTFS $KERNEL_VERSION-tinycore64


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

RUN git clone https://github.com/hishamhm/htop.git
RUN cd /htop && ./autogen.sh && ./configure --prefix=$ROOTFS --enable-cgroup && make  && make install
RUN cp /usr/lib/x86_64-linux-gnu/libtinfo.so $ROOTFS/usr/local/lib/libtinfo.so.5
RUN cp /usr/lib/x86_64-linux-gnu/libpanelw.so.5.9 $ROOTFS/usr/local/lib/libpanelw.so.5
RUN cp /usr/lib/x86_64-linux-gnu/libmenuw.so.5.9 $ROOTFS/usr/local/lib/libmenuw.so.5
RUN cp /usr/lib/x86_64-linux-gnu/libformw.so.5.9 $ROOTFS/usr/local/lib/libformw.so.5
RUN cp /lib/x86_64-linux-gnu/libncursesw.so.5.9 $ROOTFS/usr/local/lib/libncursesw.so.5
RUN cp /lib/x86_64-linux-gnu/libncurses.so.5.9 $ROOTFS/usr/local/lib/libncurses.so.5



RUN /make_iso.sh

CMD ["cat", "boot2docker.iso"]
