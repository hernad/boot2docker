FROM debian:jessie
MAINTAINER Ernad Husremovic "hernad@bring.out.ba"

ARG KERNEL_VERSION=4.4.30
ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list
RUN apt-get update -y

ENV TINYCORE_VER=8.x CURL_OPTS="--retry 4 --speed-limit 500 --speed-time 30"
RUN  apt-get update && apt-get --fix-missing -y install wget unzip \
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
                        automake \
                        pkg-config \
                        uuid-dev \
                        libncursesw5-dev libncurses-dev \
                        libfuse2 libtool autoconf vim \
                        libglib2.0-dev \
                        libfuse-dev \
                        libtirpc-dev \
                        gettext \
                        p7zip-full \
                        liblz4-tool

# tiny core rootfs location
#ENV ROOTFS=/rootfs TCL_REPO_BASE=http://tinycorelinux.net/${TINYCORE_VER}/x86_64
ENV ROOTFS=/rootfs TCL_REPO_BASE=http://distro.ibiblio.org/tinycorelinux/${TINYCORE_VER}/x86_64
ENV GCC_M -m64
# https://www.kernel.org/pub/linux/kernel/v4.x/

ENV KERNEL_MAJOR=4 KERNEL_VERSION_DOWNLOAD=$KERNEL_VERSION
ENV LINUX_BRAND=greenbox LINUX_KERNEL_SOURCE=/usr/src/linux

# Fetch the kernel sources
RUN mkdir -p /usr/src && \
    echo "https://www.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR}.x/linux-$KERNEL_VERSION_DOWNLOAD.tar.xz" &&\
    curl $CURL_OPTS -s https://www.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR}.x/linux-$KERNEL_VERSION_DOWNLOAD.tar.xz | tar -C / -xJ && \
    mv /linux-$KERNEL_VERSION_DOWNLOAD $LINUX_KERNEL_SOURCE

# https://stackoverflow.com/questions/28949109/make-oldconfig-overwriting-value-in-config
# kernel_config.xz - kernel compress xz, .lzo4 - lzo4 compress
COPY kernel_config.xz $LINUX_KERNEL_SOURCE/.config

RUN sed -i 's/-LOCAL_LINUX_BRAND/'-"$LINUX_BRAND"'/' $LINUX_KERNEL_SOURCE/.config && \
    jobs=$(nproc) && \
    cd $LINUX_KERNEL_SOURCE && \
    make -j ${jobs} olddefconfig && \
    make -j ${jobs} bzImage && \
    make -j ${jobs} modules


# ======================= VirtualBox host install ============================================

# http://download.virtualbox.org/virtualbox/5.1.8/
ENV VBOX_VERSION=5.1.22 VBOX_BUILD=115126
ENV VBOX_ISO_SHA256 54df14f234b6aa484b94939ab0f435b5dd859417612b65a399ecc34a62060380

RUN curl $CURL_OPTS -s -LO http://download.virtualbox.org/virtualbox/${VBOX_VERSION}/VirtualBox-$VBOX_VERSION-$VBOX_BUILD-Linux_amd64.run &&\
        mkdir -p /lib ;\
        ln -s $ROOTFS/lib/modules /lib/modules ;\
        bash VirtualBox-$VBOX_VERSION-$VBOX_BUILD-Linux_amd64.run

RUN cp -av /opt/VirtualBox $ROOTFS/opt/ ;\
        cd / && curl $CURL_OPTS -sLO http://download.virtualbox.org/virtualbox/$VBOX_VERSION/Oracle_VM_VirtualBox_Extension_Pack-$VBOX_VERSION.vbox-extpack &&\
        echo y | /opt/VirtualBox/VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-$VBOX_VERSION.vbox-extpack


# Build VBox guest additions
#   (VBoxGuestAdditions_X.Y.Z.iso SHA256, for verification)
RUN set -x && \
    mkdir -p /vboxguest && \
    cd /vboxguest && \
    \
    curl $CURL_OPTS -sfL -o vboxguest.iso http://download.virtualbox.org/virtualbox/${VBOX_VERSION}/VBoxGuestAdditions_${VBOX_VERSION}.iso && \
    echo "${VBOX_ISO_SHA256} *vboxguest.iso" | sha256sum -c - && \
    7z x vboxguest.iso -ir'!VBoxLinuxAdditions.run' && \
    rm vboxguest.iso && \
    \
    sh VBoxLinuxAdditions.run --noexec --target . && \
    mkdir amd64 && tar -C amd64 -xjf VBoxGuestAdditions-amd64.tar.bz2 && \
    rm VBoxGuestAdditions*.tar.bz2

# TODO figure out how to make this work reasonably (these tools try to read /proc/self/exe at startup, even for a simple "--version" check)
## verify that all the above actually worked (at least producing a valid binary, so we don't repeat issue #1157)
#RUN set -x && \
#    chroot "$ROOTFS" VBoxControl --version && \
#    chroot "$ROOTFS" VBoxService --version



# =======================  tiny core =====================================================
# The post kernel build process
# list tczs: http://distro.ibiblio.org/tinycorelinux/${TINYCORE_VER}/x86/tcz/


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
RUN curl $CURL_OPTS -sL http://http.debian.net/debian/pool/main/libc/libcap2/libcap2_2.22.orig.tar.gz | tar -C / -xz && \
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

# Prepare the ISO directory with the kernel
RUN cp -v $LINUX_KERNEL_SOURCE/arch/x86_64/boot/bzImage /tmp/iso/boot/vmlinuz64


ENV TCZ_DEPS_0      iptables \
                    iproute2 \
                    openssh openssl \
                    tar e2fsprogs \
                    gcc_libs \
                    acpid \
                    ca-certificates \
                    xz liblzma \
                    libgpg-error libgcrypt libssh2 \
                    curl acl attr ntpclient \
                    bash readline ncurses \
                    udev-lib


# Install the base tiny linux dependencies
RUN for dep in $TCZ_DEPS_0 ; do \
        echo "Download $TCL_REPO_BASE/tcz/$dep.tcz"  && \
        curl $CURL_OPTS -sL -o /tmp/$dep.tcz $TCL_REPO_BASE/tcz/$dep.tcz && \
        if [ ! -s /tmp/$dep.tcz ] ; then \
          echo "$TCL_REPO_BASE/tcz/$dep.tcz size is zero 0 - error !" && \
          exit 1 ;\
        else \
          unsquashfs -i -f -d $ROOTFS /tmp/$dep.tcz && \
          rm -f /tmp/$dep.tcz ;\
          if [ "$?" != "0" ] ; then exit 1 ; fi ;\
        fi ;\
    done



# Download the rootfs, don't unpack it though:
RUN curl $CURL_OPTS -L -o /tcl_rootfs.gz $TCL_REPO_BASE/release/distribution_files/rootfs64.gz
# Install Tiny Core Linux rootfs
RUN cd $ROOTFS && zcat /tcl_rootfs.gz | cpio -f -i -H newc -d --no-absolute-filenames


# debian jessie no /usr/lib/syslinux/isohdpfx.bin
# get syslinux 6.04 from source https://www.kernel.org/pub/linux/utils/boot/syslinux/Testing/
RUN export SYSLINUX_VER=6.04 && export SYSLINUX_PRE=pre1 &&\
   curl $CURL_OPTS -LO https://www.kernel.org/pub/linux/utils/boot/syslinux/Testing/$SYSLINUX_VER/syslinux-$SYSLINUX_VER-$SYSLINUX_PRE.tar.xz &&\
   tar xf syslinux-${SYSLINUX_VER}-${SYSLINUX_PRE}.tar.xz && cd syslinux-${SYSLINUX_VER}-${SYSLINUX_PRE} && make install

# uses bootscript to detect VirtualBox session - has to be firmware!
RUN  apt-get build-dep -y lshw &&\
     cd / && git clone https://github.com/lyonel/lshw.git && cd lshw &&\
     make && make DESTDIR=$ROOTFS install


ENV KERNELDIR=/usr/src/linux
# VirtualBox install kernel drivers
#RUN echo ignoring depmod -a errors
RUN cd /opt/VirtualBox/src/vboxhost && KERN_DIR=$LINUX_KERNEL_SOURCE make MODULE_DIR=$ROOTFS/lib/modules/$KERNEL_VERSION-$LINUX_BRAND/extra/vbox install || true

RUN cd /vboxguest && KERN_DIR=$LINUX_KERNEL_SOURCE make -C amd64/src/vboxguest-${VBOX_VERSION} \
    MODULE_DIR=$ROOTFS/lib/modules/$KERNEL_VERSION-$LINUX_BRAND/extra/vbox  &&\
    cp amd64/src/vboxguest-${VBOX_VERSION}/*.ko $ROOTFS/lib/modules/$KERNEL_VERSION-$LINUX_BRAND/extra/vbox

RUN cd /vboxguest && mkdir -p $ROOTFS/sbin && \
    cp amd64/lib/VBoxGuestAdditions/mount.vboxsf amd64/sbin/VBoxService $ROOTFS/sbin/ && \
    mkdir -p $ROOTFS/bin && \
    cp amd64/bin/VBoxClient amd64/bin/VBoxControl $ROOTFS/bin/


RUN curl $CURL_OPTS -sLO https://www.netfilter.org/projects/libmnl/files/libmnl-1.0.4.tar.bz2 &&\
    tar xf libmnl*.bz2 && rm libmnl*.bz2 &&\
    cd libmnl* &&\
    ./configure && make install &&\
    # first install is for next build, second install is for iso rootfs/usr/lib/
    make DESTDIR=$ROOTFS install

# https://git.zx2c4.com/WireGuard/refs/

ENV WIRE_GUARD_VER=0.0.20170517
RUN curl $CURL_OPTS -sLO https://git.zx2c4.com/WireGuard/snapshot/WireGuard-${WIRE_GUARD_VER}.tar.xz &&\
    tar xvf WireGuard*xz && rm WireGuard*xz &&\
    cd WireGuard*/src &&\
    #make -C /lib/modules/4.10.15-greenbox/build M=/WireGuard-0.0.20170421/src modules
    KERNELDIR=$LINUX_KERNEL_SOURCE make &&\
    make -C tools DESTDIR=$ROOTFS install &&\
    ls -lr &&\
    mkdir -p $ROOTFS/lib/modules/$KERNEL_VERSION-$LINUX_BRAND/extra/wg &&\
    cp *.ko $ROOTFS/lib/modules/$KERNEL_VERSION-$LINUX_BRAND/extra/wg/

# http://zfsonlinux.org/
# https://github.com/zfsonlinux/zfs/releases/download/zfs-0.6.5.8/spl-0.6.5.8.tar.gz
ENV ZFS_VER 0.7.0-rc4
#ENV ZFS_VER 0.6.5.9
RUN mkdir /zfs && cd /zfs && curl $CURL_OPTS -sLO https://github.com/zfsonlinux/zfs/releases/download/zfs-$ZFS_VER/spl-$ZFS_VER.tar.gz &&\
    cd /zfs && tar xf spl-$ZFS_VER.tar.gz && cd spl-* &&\
    ./configure --with-linux=$LINUX_KERNEL_SOURCE && make && make install

# hernad: zfs build demands librt from debian
RUN cd /lib/x86_64-linux-gnu && ls librt-2*.so && cp librt-2.19.so $ROOTFS/lib/ &&\
    rm $ROOTFS/lib/librt.so.1 &&\
    cd $ROOTFS/lib && ln -s librt-2.19.so librt.so.1

# build zfs from git
# ENV ZFS_GIT_BRANCH zfs-0.6.4-release
# RUN cd /zfs && git clone https://github.com/zfsonlinux/zfs.git zfs-git && cd /zfs/zfs-git && git checkout $ZFS_GIT_BRANCH
# RUN cd /zfs/zfs-git && sh autogen.sh && ./configure --with-linux=$LINUX_KERNEL_SOURCE && make && DESTDIR=$ROOTFS make install


RUN apt-get install -y libblkid-dev libattr1-dev

# build zfs from tar
RUN cd /zfs && curl $CURL_OPTS -sLO https://github.com/zfsonlinux/zfs/releases/download/zfs-$ZFS_VER/zfs-$ZFS_VER.tar.gz &&\
    cd /zfs && tar xf zfs-$ZFS_VER.tar.gz && cd zfs-* &&\
    ./configure --with-linux=$LINUX_KERNEL_SOURCE && make &&\
    DESTDIR=$ROOTFS make install

# Install the kernel modules in $ROOTFS
RUN cd $LINUX_KERNEL_SOURCE &&\
    make INSTALL_MOD_PATH=$ROOTFS modules_install firmware_install &&\
    depmod -a -b $ROOTFS $KERNEL_VERSION-$LINUX_BRAND


# debug http://unix.stackexchange.com/questions/76490/no-such-file-or-directory-on-an-executable-yet-file-exists-and-ldd-reports-al
# /lib64/ld-linux-x86-64.so.2.
RUN cd $ROOTFS && ln -s lib lib64

# fix "su -"
RUN echo root > $ROOTFS/etc/sysconfig/superuser

RUN rm -r -f $ROOTFS/opt/VirtualBox

# glibc_apps: /usr/bin/localedef
ENV TCZ_DEPS_1 getlocale glibc_i18n_locale glibc_apps glibc_gconv

RUN for dep in $TCZ_DEPS_1 ; do \
        echo "Download $TCL_REPO_BASE/tcz/$dep.tcz"  && \
        curl $CURL_OPTS -sL -o /tmp/$dep.tcz $TCL_REPO_BASE/tcz/$dep.tcz && \
        if [ ! -s /tmp/$dep.tcz ] ; then \
          echo "$TCL_REPO_BASE/tcz/$dep.tcz size is zero 0 - error !" && \
          exit 1 ;\
        else \
          unsquashfs -i -f -d $ROOTFS /tmp/$dep.tcz && \
          rm -f /tmp/$dep.tcz ;\
          if [ "$?" != "0" ] ; then exit 1 ; fi ;\
        fi ;\
    done



ENV BTRFS_VER=4.11
RUN  apt-get install -y asciidoc xmlto --no-install-recommends &&\
     curl $CURL_OPTS -LO https://github.com/kdave/btrfs-progs/archive/v4.11.tar.gz && tar xf v${BTRFS_VER}.tar.gz &&\
     cd btrfs-progs-${BTRFS_VER} &&\
     ./autogen.sh &&\
     ./configure &&\
     make install

# ========== /opt/apps/docker ==================================

# https://github.com/moby/moby/releases
COPY DOCKER_VERSION $ROOTFS/etc/sysconfig/docker

# get generate_cert
ENV GENERATE_CERT_VER=0.3
RUN mkdir -p /opt/apps/docker/bin &&\
      curl $CURL_OPTS -fsL -o /opt/apps/docker/bin/generate_cert https://github.com/SvenDowideit/generate_cert/releases/download/${GENERATE_CERT_VER}/generate_cert-${GENERATE_CERT_VER}-linux-amd64

RUN curl $CURL_OPTS -sL  https://get.docker.com/builds/Linux/x86_64/docker-$(cat $ROOTFS/etc/sysconfig/docker).tgz | tar -C / -xz && \
    mv /docker/* /opt/apps/docker/bin/ &&\
    chmod +x /opt/apps/docker/bin/*

# =============================================================================================

COPY GREENBOX_VERSION $ROOTFS/etc/sysconfig/greenbox
COPY GREENBOX_BUILD $ROOTFS/etc/sysconfig/greenbox_build

COPY rootfs/rootfs $ROOTFS

# crontab
COPY rootfs/crontab $ROOTFS/var/spool/cron/crontabs/root

# set ttyS0 115200
COPY rootfs/inittab $ROOTFS/etc/inittab
COPY rootfs/securetty $ROOTFS/etc/securetty
COPY rootfs/ld.so.conf $ROOTFS/etc/ld.so.conf

# tinycore openssh uses /usr/local/etc/ssh
RUN  mkdir -p $ROOTFS/usr/local/etc/ssh   &&\
     mkdir -p $ROOTFS/etc/init.d/services

COPY rootfs/sshd_config $ROOTFS/usr/local/etc/ssh/sshd_config

COPY rootfs/openssh $ROOTFS/usr/local/etc/init.d/openssh

COPY rootfs/services/* $ROOTFS/etc/init.d/services/


COPY rootfs/sethostname $ROOTFS/usr/bin/sethostname

COPY rootfs/rcS $ROOTFS/etc/init.d/rcS
COPY rootfs/rc.shutdown $ROOTFS/etc/init.d/rc.shutdown
COPY rootfs/dhcp.sh $ROOTFS/etc/init.d/dhcp.sh
COPY rootfs/busybox-aliases $ROOTFS/etc/init.d/busybox-aliases
COPY rootfs/tc-functions $ROOTFS/etc/init.d/tc-functions


COPY rootfs/tc-config $ROOTFS/etc/init.d/tc-config
COPY rootfs/cgroupfs-mount $ROOTFS/etc/rc.d/cgroupfs-mount
COPY rootfs/docker $ROOTFS/etc/init.d/docker

COPY rootfs/environment $ROOTFS/etc/environment
COPY rootfs/sshrc $ROOTFS/usr/local/etc/ssh/sshrc
COPY rootfs/green_common $ROOTFS/etc/green_common
COPY rootfs/green_docker_service_common $ROOTFS/etc/green_docker_service_common
COPY rootfs/sudo_x /usr/local/bin
COPY rootfs/update-ca-certificates $ROOTFS/usr/local/sbin/update-ca-certificates
COPY rootfs/logrotate.sh $ROOTFS/usr/local/sbin/logrotate.sh

# Copy boot params
COPY rootfs/isolinux /tmp/iso/boot/isolinux
COPY rootfs/make_iso.sh /

# Make sure init scripts are executable
RUN find $ROOTFS/etc/rc.d/ $ROOTFS/usr/local/etc/init.d/ -exec chmod +x '{}' ';'


RUN cp -v $ROOTFS/etc/sysconfig/greenbox /tmp/iso/version

# Change MOTD
RUN mv $ROOTFS/usr/local/etc/motd $ROOTFS/etc/motd

# Make sure we have the correct boot shell scripts
# /opt/boot*.sh
RUN mv $ROOTFS/boot*.sh $ROOTFS/opt/ && \
        chmod +x $ROOTFS/opt/*.sh

# Make sure we have the correct shutdown
RUN mv $ROOTFS/shutdown.sh $ROOTFS/opt/shutdown.sh && \
        chmod +x $ROOTFS/opt/shutdown.sh


WORKDIR /

# remove git-cvsserver, gitk
# move zfs utilites zdb, zed, ztest to /opt/apps/green

RUN cd $ROOTFS/usr/local/bin &&\
#    rm git-cvsserver gitk &&\
    cd $ROOTFS/usr/local/share &&\
#    rm -r -f git-gui gitk gitweb &&\
    rm -r -f applications pixmaps &&\
    ( [ -d /opt/apps/green/sbin ] || mkdir -p /opt/apps/green/sbin ) &&\
    cd $ROOTFS/usr/local/sbin && mv zdb zed ztest /opt/apps/green/sbin &&\
    rm -r -f $ROOTFS/usr/local/sbin/tce*


RUN rm -rf $ROOTFS/usr/lib/gconv

# cleanup virtualbox
# chmod 4755 - VirtualBox, VBoxHeadless suid
RUN  cd /opt/VirtualBox && rm -rf ExtensionPacks/Oracle_VM_VirtualBox_Extension_Pack/win* &&\
     find -name "*.o" -exec rm {} \; &&\
     find -name "*.c" -exec rm {} \; &&\
     rm *.pdf &&\
     chown root:root -R . &&\
     chmod 4755 VirtualBox VBoxHeadless &&\
     ls -l VirtualBox VBoxHeadless && cd /

RUN cd $ROOTFS/lib/modules/*$LINUX_BRAND && rm -rf ./kernel/arch/x86/kvm &&\
    rm -rf ./kernel/fs/reiserfs &&\
    rm -rf ./kernel/lib/raid6 &&\
    rm -rf ./kernel/fs/hfsplus &&\
    rm -rf ./kernel/drivers/firewire &&\
    rm -rf ./kernel/drivers/xen &&\
    rm -rf ./kernel/drivers/input/joystick

#    rm -rf ./kernel/fs/btrfs

RUN rm $ROOTFS/usr/local/lib/*.a &&\
    rm $ROOTFS/usr/local/lib/*.la &&\
    # rm man files
    rm -rf $ROOTFS/usr/local/share/man/*

RUN rm $ROOTFS/opt/bootlocal.sh && rm $ROOTFS/opt/bootsync.sh
RUN rm $ROOTFS/usr/local/etc/ssh/*.orig

# zfs 0.7.0 dependencies
RUN cp -av /lib/x86_64-linux-gnu/libtirpc.so.1* $ROOTFS/usr/local/lib/ &&\
    cp -av /lib/x86_64-linux-gnu/libblkid.so.1* $ROOTFS/usr/local/lib/ &&\
    cp -av /usr/lib/x86_64-linux-gnu/libk5crypto* $ROOTFS/usr/local/lib/ &&\
    cp -av /usr/lib/x86_64-linux-gnu/libgssapi_krb5* $ROOTFS/usr/local/lib/ &&\
    cp -av /usr/lib/x86_64-linux-gnu/libkrb5* $ROOTFS/usr/local/lib/ &&\
    cp -av /lib/x86_64-linux-gnu/libkeyutils* $ROOTFS/usr/local/lib/


RUN ls -l $ROOTFS/usr/local/tce.installed

# /opt/boot/etc/ssl -> /usr/local/etc/ssl, /usr/etc/ssl
# /opt/boot/etc/ssl/ca-certificates -> /usr/local/share/ca-certificates
RUN rm $ROOTFS/usr/local/tce.installed/ca-certificates


RUN /make_iso.sh

CMD ["cat", "greenbox.iso"]
