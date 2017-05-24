FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list
RUN apt-get update -y

ENV APPS_DIR=/opt/apps/green CURL_OPTS="--retry 4 --speed-limit 500 --speed-time 30"
ENV CPPFLAGS="-I${APPS_DIR}/include" CFLAGS="-I${APPS_DIR}/include" LDFLAGS="-L${APPS_DIR}/lib"

# ================= ${APPS_DIR} =========================================================

#RUN apt-get build-dep -y nbd-server && apt-get install -y docbook-utils && \
#    curl -LO https://github.com/NetworkBlockDevice/nbd/archive/nbd-3.15.2.tar.gz &&\
#    tar xf nbd-*.tar.gz && rm nbd-*.tar.gz && cd nbd* &&\
#    sh autogen.sh &&\
#    ./configure CFLAGS="-I${APPS_DIR}/include" LDFLAGS="-L${APPS_DIR}/lib" --prefix=${APPS_DIR} &&\
#    make &&\
#    make install


RUN curl -sLO http://linux-pam.org/library/Linux-PAM-1.3.0.tar.bz2 &&\
    tar xf Linux-PAM*.bz2 && cd Linux-PAM* &&\
    ./configure CFLAGS="-I${APPS_DIR}/include" LDFLAGS="-L${APPS_DIR}/lib" --prefix=${APPS_DIR} &&\
    make &&\
    make install


RUN git clone https://github.com/fukuchi/libqrencode.git &&\
    cd libqrencode &&\
    libtoolize --force && aclocal && autoheader && automake --force-missing --add-missing &&\
    autoconf &&\
    ./configure CFLAGS="-I${APPS_DIR}/include" LDFLAGS="-L${APPS_DIR}/lib" --prefix=${APPS_DIR} &&\
    make &&\
    make install


RUN apt-get build-dep libpam-google-authenticator -y &&\
    git clone https://github.com/google/google-authenticator-libpam.git &&\
    cd google-authenticator-libpam &&\
   ./bootstrap.sh  && ./configure CFLAGS="-I${APPS_DIR}/include" LDFLAGS="-L${APPS_DIR}/lib" --prefix=${APPS_DIR} && make &&\
    make install

# openvpn trazi 1.0.x https://community.openvpn.net/openvpn/ticket/802

RUN curl -sLO https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.5.2.tar.gz &&\
    tar xvf libressl-* && cd libressl-* &&\
    ./config --prefix=${APPS_DIR} &&\
    make install

#RUN curl -LO https://www.openssl.org/source/openssl-1.0.2k.tar.gz &&\
#    tar xvf openssl-*.tar.gz &&\
#    cd openssl-* &&\
#    ./config --prefix=${APPS_DIR} &&\
#    make &&\
#    make install

ENV OPENVPN_VER=2.4.1

RUN apt-get build-dep openvpn -y && apt-get install net-tools -y &&\
    curl -sLO http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz &&\
    tar xvf lzo-2.10.tar.gz && cd lzo-* && ./configure --prefix=${APPS_DIR} &&\
    make install &&\
    curl -sL -o openvpn-${OPENVPN_VER}.tar.gz https://github.com/OpenVPN/openvpn/archive/v${OPENVPN_VER}.tar.gz  &&\
    tar -xf openvpn-${OPENVPN_VER}.tar.gz &&\
    cd openvpn-${OPENVPN_VER} &&\
    libtoolize --force && aclocal && autoheader && automake --force-missing --add-missing &&\
    autoconf &&\
    ls ${APPS_DIR}/include/lzo &&\
    ./configure --prefix=${APPS_DIR} CFLAGS="-I${APPS_DIR}/include" LDFLAGS="-L${APPS_DIR}/lib" OPENSSL_LIBS="-L${APPS_DIR}/lib -lssl -lcrypto" OPENSSL_CFLAGS="-I${APPS_DIR}/include" --disable-debug --disable-dependency-tracking --disable-silent-rules --with-crypto-library=openssl &&\
    make &&\
    make install

# == logrotate ==
ENV LOGROTATE_VER=3.11.0
RUN apt-get install -y libpopt-dev
RUN curl -k -sLO https://github.com/logrotate/logrotate/releases/download/$LOGROTATE_VER/logrotate-$LOGROTATE_VER.tar.gz &&\
   tar xvf logrotate-$LOGROTATE_VER.tar.gz &&\
   cd /logrotate-$LOGROTATE_VER &&\
   export LDFLAGS="-static" && ./configure --prefix=${APPS_DIR} &&\
   make && make install &&  mkdir -p ${APPS_DIR}/bin && mv ${APPS_DIR}/sbin/* ${APPS_DIR}/bin &&\
   ls -lh ${APPS_DIR}/bin/logrotate


# === rsync 3.1.2, 2015-12-21===
ENV RSYNC_VER=3.1.2
RUN mkdir -p ${APPS_DIR}/bin &&\
    cd / && curl -LO https://download.samba.org/pub/rsync/src/rsync-${RSYNC_VER}.tar.gz &&\
    tar xvf rsync-${RSYNC_VER}.tar.gz &&\
    cd /rsync-${RSYNC_VER} && ./configure && make && /usr/bin/install -c  -m 755 rsync ${APPS_DIR}/bin


# === tmux & libevent install =====
RUN curl -sLO  https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz &&\
    tar xvf libevent-2.0.22-stable.tar.gz &&\
    cd /libevent-2.0.22-stable && sh autogen.sh && ./configure && make install &&\
    ( [  -d ${APPS_DIR}/lib ] || mkdir -p ${APPS_DIR}/lib ) &&\
    cp .libs/*so* ${APPS_DIR}/lib
RUN git clone https://github.com/ThomasAdam/tmux.git tmux &&\
    cd tmux && sh autogen.sh && export LD_LIBRARY_PATH=${APPS_DIR}/lib && ./configure && make &&\
    ( [  -d ${APPS_DIR}/bin ] || mkdir -p ${APPS_DIR}/bin ) &&\
    cp tmux ${APPS_DIR}/bin/tmux && chmod +x ${APPS_DIR}/bin/tmux &&\
    cp /usr/lib/x86_64-linux-gnu/libtinfo.so ${APPS_DIR}/lib/libtinfo.so.5


RUN  export LZO_VER=2.09 && curl -sLO http://www.oberhumer.com/opensource/lzo/download/lzo-${LZO_VER}.tar.gz &&\
     tar xvf lzo-${LZO_VER}.tar.gz && cd lzo-${LZO_VER} && ./configure --prefix=${APPS_DIR} &&\
     make install && ls -lr ${APPS_DIR}

RUN  export LD_LIBRARY_PATH=${APPS_DIR}/lib &&\
     export CPPFLAGS="-I${APPS_DIR}/include -L${APPS_DIR}/lib" &&\
     export LDFLAGS="-L${APPS_DIR}/lib" &&\
     export LZOP_VER=1.03 && cd / && curl -sLO http://www.lzop.org/download/lzop-${LZOP_VER}.tar.gz &&\
     tar xvf lzop-${LZOP_VER}.tar.gz && cd lzop-${LZOP_VER} &&\
     ./configure --prefix=${APPS_DIR} && make install


RUN  export PCIUTILS_VER=3.4.0 && cd / && curl -sLO ftp://atrey.karlin.mff.cuni.cz/pub/linux/pci/pciutils-${PCIUTILS_VER}.tar.gz &&\
    tar xvf pciutils-${PCIUTILS_VER}.tar.gz && cd pciutils-${PCIUTILS_VER} &&\
    make && make PREFIX= DESTDIR=${APPS_DIR}  install


#http://libguestfs.org/download/1.31-development/libguestfs-1.31.30.tar.gz

RUN   apt-get install -y libusb-1.0-0 libusb-1.0-0-dev libudev1 libudev-dev &&\
      git clone https://github.com/gregkh/usbutils.git &&\
        cp /usr/lib/x86_64-linux-gnu/libusb*.so ${APPS_DIR}/lib &&\
        cp /usr/lib/x86_64-linux-gnu/libudev*.so ${APPS_DIR}/lib &&\
	      cd usbutils && git submodule init && git submodule update &&\
	      ./autogen.sh --prefix=${APPS_DIR} &&\
	      make && make install

RUN  apt-get update -y &&\
     apt-get -y install gcc libffi-dev libssl-dev python2.7 python2.7-dev  &&\
     ln -s /opt/apps/python2 /opt/python2

# ==== pipework in green ====
RUN  cd ${APPS_DIR}/bin &&  curl -sLO https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework &&\
     chmod +x pipework

#RUN  apt-get update -y && apt-get install -y bridge-utils openvswitch-switch &&\
#     cp /sbin/brctl ${APPS_DIR}/bin/ &&\
#     cp `which ovs-vsctl` ${APPS_DIR}/bin/ &&\
#     cp `which truncate` ${APPS_DIR}/bin/


# green_app/gdrive
# https://github.com/prasmussen/gdrive
#RUN curl -L https://docs.google.com/uc?id=0B3X9GlR6EmbnQ0FtZmJJUXEyRTA\&export=download > ${APPS_DIR}/bin/gdrive &&\
#   ls ${APPS_DIR}/bin/gdrive ; chmod +x ${APPS_DIR}/bin/gdrive

# green_app/dbxcli - dropbox client
# ne treba imamo rclone
#ENV DROPBOX_VER=1.4.0
#RUN curl -LO https://github.com/dropbox/dbxcli/releases/download/v${DROPBOX_VER}/dbxcli-linux-amd64 &&\
#    mv dbxcli-linux-amd64 ${APPS_DIR}/bin/dbxcli && chmod +x ${APPS_DIR}/bin/dbxcli


RUN  curl -sLO https://github.com/ncw/rclone/releases/download/v1.36/rclone-v1.36-linux-amd64.zip &&\
     unzip rclone-v*-linux-amd64.zip &&\
     chmod +x rclone-*linux-amd64/rclone &&\
     mv rclone*-linux-amd64/rclone ${APPS_DIR}/bin/

ENV FRP_VER 0.9.3
RUN  curl -sLO https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_linux_amd64.tar.gz &&\
     tar xf frp*.tar.gz &&\
     cd frp_*linux_amd64/ &&\
     chmod +x frps frpc &&\
     mv frps frpc ${APPS_DIR}/bin/


ENV TCL_REPO_BASE=http://tinycorelinux.net/${TINYCORE_VER}/x86_64
ENV TCZ_DEPS_DEV    curl-dev \
                    openssl-dev \
                    ncurses-dev \
                    ncurses \
                    ncurses5 \
                    expat2-dev \
                    readline-dev \
                    libxml2-dev \
                    # fwknop
                    libpcap-dev

ENV ROOTFS=/
# Install the base tiny linux build
RUN for dep in $TCZ_DEPS_DEV ; do \
        echo "Download $TCL_REPO_BASE/tcz/$dep.tcz"  && \
        curl -sL -o /tmp/$dep.tcz $TCL_REPO_BASE/tcz/$dep.tcz && \
        if [ ! -s /tmp/$dep.tcz ] ; then \
            echo "$TCL_REPO_BASE/tcz/$dep.tcz size is zero 0 - error !" && \
            exit 1 ;\
        else \
            unsquashfs -i -f -d $ROOTFS /tmp/$dep.tcz && \
            rm -f /tmp/$dep.tcz ;\
            if [ "$?" != "0" ] ; then exit 1 ; fi ;\
        fi ;\
done


ENV ROOTFS=${APPS_DIR}
ENV TCL_REPO_BASE=http://tinycorelinux.net/${TINYCORE_VER}/x86_64
ENV TCZ_DEPS_GREEN  \
                    htop ncurses-utils ncurses-terminfo \
                    git expat2 \
                    patch pcre \
                    parted liblvm2 \
                    procps \
                    bind-utilities libxml2 \
                    fuse libffi \
                    #fwknop
                    libpcap


# Install the base tiny linux build
RUN for dep in $TCZ_DEPS_GREEN ; do \
        echo "Download $TCL_REPO_BASE/tcz/$dep.tcz"  && \
        curl -sL -o /tmp/$dep.tcz $TCL_REPO_BASE/tcz/$dep.tcz && \
        if [ ! -s /tmp/$dep.tcz ] ; then \
            echo "$TCL_REPO_BASE/tcz/$dep.tcz size is zero 0 - error !" && \
            exit 1 ;\
        else \
            unsquashfs -i -f -d $ROOTFS /tmp/$dep.tcz && \
            rm -f /tmp/$dep.tcz ;\
            if [ "$?" != "0" ] ; then exit 1 ; fi ;\
        fi ;\
done


RUN  curl -sLO http://www.harding.motd.ca/autossh/autossh-1.4e.tgz &&\
      tar xf autossh-1.4e.tgz &&\
      cd autossh-1.4e &&\
      ./configure --prefix=${APPS_DIR} &&\
      make && make install


RUN   curl $CURL_OPTS -sLO http://www.cipherdyne.org/fwknop/download/fwknop-2.6.9.tar.bz2 &&\
      tar xf fwknop-*.tar.bz2 && rm fw*.bz2 && cd fwknop* &&\
      ./configure --prefix=${APPS_DIR} &&\
      make && make install


RUN   curl $CURL_OPTS -sLO https://releases.hashicorp.com/vault/0.7.2/vault_0.7.2_linux_amd64.zip &&\
      unzip vault*.zip && chmod +x vault && mv vault ${APPS_DIR}/bin/ && rm vault*zip


RUN   curl $CURL_OPTS -sLO https://github.com/coredns/coredns/releases/download/v007/coredns_007_linux_x86_64.tgz &&\
      tar xz coredns*tgz && chmod +x coredns && mv coredns ${APPS_DIR}/bin/ && rm coredns*tgz

# ====================================== remove what we don't need  ==============================

RUN mkdir -p ${APPS_DIR}/bin ;\
    mkdir -p ${APPS_DIR}/lib ;\
    mkdir -p ${APPS_DIR}/share ;\
    cp -av ${APPS_DIR}/usr/local/bin/* ${APPS_DIR}/bin/ &&\
    cp -av ${APPS_DIR}/usr/local/sbin/* ${APPS_DIR}/bin/ &&\
    cp -av ${APPS_DIR}/usr/local/lib/* ${APPS_DIR}/lib/ &&\
    cp -av ${APPS_DIR}/usr/local/share/* ${APPS_DIR}/share/ &&\
    rm -rf ${APPS_DIR}/usr &&\
    # git out
    rm -rf ${APPS_DIR}/bin/git-cvsserver &&\
    rm -rf ${APPS_DIR}/lib/git-core/git-cvs* &&\
    rm -rf ${APPS_DIR}/lib/git-core/git-svn* &&\
    rm -rf ${APPS_DIR}/lib/git-core/git-web--browse* &&\
    # erase tcpdump.4.8.1
    rm -rf ${APPS_DIR}/bin/tcpdump.* &&\
    # erase static libraries, includes in ${APPS_DIR}
    rm ${APPS_DIR}/lib/*.a &&\
    rm ${APPS_DIR}/lib/*.la && echo green_apps removing static libraries &&\
    rm -rf ${APPS_DIR}/include/ ; echo green_apps removing include files &&\
    rm -rf ${APPS_DIR}/share/terminfo ${APPS_DIR}/share/git-gui ${APPS_DIR}/share/applications &&\
    mv ${APPS_DIR}/sbin/* ${APPS_DIR}/bin/ ; rmdir ${APPS_DIR}/sbin &&\
    rm -rf /opt/apps/go/test ; echo rm golang test directory &&\
    # manuals out
    rm -rf ${APPS_DIR}/man ${APPS_DIR}/share/doc ${APPS_DIR}/share/man ;\
    rm -rf ${APPS_DIR}/usr ${APPS_DIR}/var &&\
    rm -rf ${APPS_DIR}/share/gnupg/*.txt && rm -rf ${APPS_DIR}/share/gitweb  ${APPS_DIR}/share/pixmaps &&\
    # rm locales except bs
    mkdir -p /tmp/locale && mv ${APPS_DIR}/share/locale/bs /tmp/locale/ && rm -rf ${APPS_DIR}/share/locale/* &&\
    mv /tmp/locale/bs ${APPS_DIR}/share/locale/ &&\
    rm -f '${APPS_DIR}/share/]' &&\
    rm ${APPS_DIR}/bin/tcpdump.*


#RUN ls -ld ${APPS_DIR}/* ; ls -l ${APPS_DIR}/bin/ ; ls -l ${APPS_DIR}/lib/
# collect shared libraries needed for green apps execution

#RUN mv /opt/apps/lib/man-db/*.so /opt/apps/lib ; rm -rf /opt/apps/lib/man-db

COPY extract_so_deps_green.sh /
RUN bash  /extract_so_deps_green.sh
