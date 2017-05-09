FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list
RUN apt-get update -y


ENV CPPFLAGS="-I/opt/apps/green/include" CFLAGS="-I/opt/apps/green/include" LDFLAGS="-L/opt/apps/green/lib"

# ================= /opt/apps/green =========================================================

#RUN apt-get build-dep -y nbd-server && apt-get install -y docbook-utils && \
#    curl -LO https://github.com/NetworkBlockDevice/nbd/archive/nbd-3.15.2.tar.gz &&\
#    tar xf nbd-*.tar.gz && rm nbd-*.tar.gz && cd nbd* &&\
#    sh autogen.sh &&\
#    ./configure CFLAGS="-I/opt/apps/green/include" LDFLAGS="-L/opt/apps/green/lib" --prefix=/opt/apps/green &&\
#    make &&\
#    make install

ENV XNBD_VER=0.4.0
RUN apt-get build-dep -y xnbd &&\
    curl -LO https://bitbucket.org/hirofuchi/xnbd/downloads/xnbd-${XNBD_VER}.tgz &&\
    tar xf xnbd-${XNBD_VER}.tgz &&\
    cd xnbd-${XNBD_VER} &&\
    autoreconf -i &&\
    ./configure CFLAGS="-I/opt/apps/green/include" LDFLAGS="-L/opt/apps/green/lib" --prefix=/opt/apps/green &&\
    make


RUN curl -LO http://downloads.es.net/pub/iperf/iperf-3-current.tar.gz &&\
    tar xf iperf-3*.tar.gz && rm iperf-3*.tar.gz && cd iperf* &&\
    ./configure CFLAGS="-I/opt/apps/green/include" LDFLAGS="-L/opt/apps/green/lib" --prefix=/opt/apps/green &&\
    make &&\
    make install


# == qperf 0.4.9, 2012-11-07 ===
RUN cd /tmp && curl -LO https://www.openfabrics.org/downloads/qperf/qperf-0.4.9.tar.gz &&\
        tar xvf qperf-0.4.9.tar.gz &&\
        cd /tmp/qperf-0.4.9 && sh autogen.sh && \
        ./configure && make && /usr/bin/install -c src/qperf /opt/apps/green/bin &&\
        cd /tmp && rm qperf-0.4.9.tar.gz && rm -r -f qperf-0.4.9

# ---------- fio http://jrs-s.net/2015/11/23/fio-cheat-sheet/ ------------
# fio - Flexible IO Tester
# http://git.kernel.dk/?p=fio.git;a=summary,  last change	Sat, 8 Apr 2017 19:04:21 +0200 (11:04 -0600)
RUN git clone git://git.kernel.dk/fio.git &&\
      cd fio && ./configure --prefix=/opt/apps/green &&\
      make install


RUN curl -LO http://linux-pam.org/library/Linux-PAM-1.3.0.tar.bz2 &&\
    tar xf Linux-PAM*.bz2 && cd Linux-PAM* &&\
    ./configure CFLAGS="-I/opt/apps/green/include" LDFLAGS="-L/opt/apps/green/lib" --prefix=/opt/apps/green &&\
    make &&\
    make install


RUN git clone https://github.com/fukuchi/libqrencode.git &&\
    cd libqrencode &&\
    libtoolize --force && aclocal && autoheader && automake --force-missing --add-missing &&\
    autoconf &&\
    ./configure CFLAGS="-I/opt/apps/green/include" LDFLAGS="-L/opt/apps/green/lib" --prefix=/opt/apps/green &&\
    make &&\
    make install


RUN apt-get build-dep libpam-google-authenticator -y &&\
    git clone https://github.com/google/google-authenticator-libpam.git &&\
    cd google-authenticator-libpam &&\
   ./bootstrap.sh  && ./configure CFLAGS="-I/opt/apps/green/include" LDFLAGS="-L/opt/apps/green/lib" --prefix=/opt/apps/green && make &&\
    make install

# openvpn trazi 1.0.x https://community.openvpn.net/openvpn/ticket/802

RUN curl -LO https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.5.2.tar.gz &&\
    tar xvf libressl-* && cd libressl-* &&\
    ./config --prefix=/opt/apps/green &&\
    make install

#RUN curl -LO https://www.openssl.org/source/openssl-1.0.2k.tar.gz &&\
#    tar xvf openssl-*.tar.gz &&\
#    cd openssl-* &&\
#    ./config --prefix=/opt/apps/green &&\
#    make &&\
#    make install

ENV OPENVPN_VER=2.4.1

RUN apt-get build-dep openvpn -y && apt-get install net-tools -y &&\
    curl -LO http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz &&\
    tar xvf lzo-2.10.tar.gz && cd lzo-* && ./configure --prefix=/opt/apps/green &&\
    make install &&\
    curl -L -o openvpn-${OPENVPN_VER}.tar.gz https://github.com/OpenVPN/openvpn/archive/v${OPENVPN_VER}.tar.gz  &&\
    tar -xf openvpn-${OPENVPN_VER}.tar.gz &&\
    cd openvpn-${OPENVPN_VER} &&\
    libtoolize --force && aclocal && autoheader && automake --force-missing --add-missing &&\
    autoconf &&\
    ls /opt/apps/green/include/lzo &&\
    ./configure --prefix=/opt/apps/green CFLAGS="-I/opt/apps/green/include" LDFLAGS="-L/opt/apps/green/lib" OPENSSL_LIBS="-L/opt/apps/green/lib -lssl -lcrypto" OPENSSL_CFLAGS="-I/opt/apps/green/include" --disable-debug --disable-dependency-tracking --disable-silent-rules --with-crypto-library=openssl &&\
    make &&\
    make install

# == logrotate ==
ENV LOGROTATE_VER=3.11.0
RUN apt-get install -y libpopt-dev
RUN curl -k -LO https://github.com/logrotate/logrotate/releases/download/$LOGROTATE_VER/logrotate-$LOGROTATE_VER.tar.gz &&\
   tar xvf logrotate-$LOGROTATE_VER.tar.gz &&\
   cd /logrotate-$LOGROTATE_VER &&\
   export LDFLAGS="-static" && ./configure --prefix=/opt/apps/green &&\
   make && make install &&  mkdir -p /opt/apps/green/bin && mv /opt/apps/green/sbin/* /opt/apps/green/bin &&\
   ls -lh /opt/apps/green/bin/logrotate


# === rsync 3.1.2, 2015-12-21===
ENV RSYNC_VER=3.1.2
RUN mkdir -p /opt/apps/green/bin &&\
    cd / && curl -LO https://download.samba.org/pub/rsync/src/rsync-${RSYNC_VER}.tar.gz &&\
    tar xvf rsync-${RSYNC_VER}.tar.gz &&\
    cd /rsync-${RSYNC_VER} && ./configure && make && /usr/bin/install -c  -m 755 rsync /opt/apps/green/bin

# Pipe Viewer - is a terminal-based tool for monitoring the progress of data through a pipeline.
# pv 1.6.0, 15 Mar 2015
RUN curl -LO http://www.ivarch.com/programs/sources/pv-1.6.0.tar.gz  &&\
    tar xvf pv-1.6.0.tar.gz  &&\
    cd /pv-1.6.0 && ./configure && make && /usr/bin/install -c pv /opt/apps/green/bin


# RUN curl -LO https://github.com/zfsonlinux/zfs-auto-snapshot/archive/master.zip &&\
#    unzip master.zip &&\
#    cd zfs-auto-snapshot-master && /usr/bin/install src/zfs-auto-snapshot.sh /opt/apps/green/bin/zfs-auto-snapshot



# === tmux & libevent install =====
RUN curl -LO  https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz &&\
    tar xvf libevent-2.0.22-stable.tar.gz &&\
    cd /libevent-2.0.22-stable && sh autogen.sh && ./configure && make install &&\
    ( [  -d /opt/apps/green/lib ] || mkdir -p /opt/apps/green/lib ) &&\
    cp .libs/*so* /opt/apps/green/lib
RUN git clone https://github.com/ThomasAdam/tmux.git tmux &&\
    cd tmux && sh autogen.sh && export LD_LIBRARY_PATH=/opt/apps/green/lib && ./configure && make &&\
    ( [  -d /opt/apps/green/bin ] || mkdir -p /opt/apps/green/bin ) &&\
    cp tmux /opt/apps/green/bin/tmux && chmod +x /opt/apps/green/bin/tmux &&\
    cp /usr/lib/x86_64-linux-gnu/libtinfo.so /opt/apps/green/lib/libtinfo.so.5

# ==== ag - the silver searcher ===========
RUN  apt-get install -y automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev &&\
     cd / ; git clone https://github.com/ggreer/the_silver_searcher.git &&\
     cd the_silver_searcher && export LDFLAGS="-static" && ./build.sh --prefix=/opt/apps/green &&\
     make install


# ==== mbuffer =========
# Version 20161115 md5=b81940da5b750c6adda65dfbf8b2ad36
# http://www.maier-komor.de/software/mbuffer/mbuffer-20161115.tgz
# http://www.maier-komor.de/mbuffer.html

RUN export MBUFFER_VER="20161115" && echo "mbuffer ver: $MBUFFER_VER" && curl -LO http://www.maier-komor.de/software/mbuffer/mbuffer-${MBUFFER_VER}.tgz &&\
    cd / && tar xvf mbuffer-${MBUFFER_VER}.tgz && cd mbuffer-${MBUFFER_VER} && ./configure --prefix=/opt/apps/green &&\
    make install

RUN  export LZO_VER=2.09 && curl -LO http://www.oberhumer.com/opensource/lzo/download/lzo-${LZO_VER}.tar.gz &&\
     tar xvf lzo-${LZO_VER}.tar.gz && cd lzo-${LZO_VER} && ./configure --prefix=/opt/apps/green &&\
     make install && ls -lr /opt/apps/green

RUN  export LD_LIBRARY_PATH=/opt/apps/green/lib &&\
     export CPPFLAGS="-I/opt/apps/green/include -L/opt/apps/green/lib" &&\
     export LDFLAGS="-L/opt/apps/green/lib" &&\
     export LZOP_VER=1.03 && cd / && curl -LO http://www.lzop.org/download/lzop-${LZOP_VER}.tar.gz &&\
     tar xvf lzop-${LZOP_VER}.tar.gz && cd lzop-${LZOP_VER} &&\
     ./configure --prefix=/opt/apps/green && make install


# perl-5.24.1.tar.xz	14-Jan-2017 12:05	11M
RUN export PERL_VER=5.24.1 && cd / && curl -LO http://www.cpan.org/src/5.0/perl-${PERL_VER}.tar.xz &&\
    tar xf perl-${PERL_VER}.tar.xz &&  cd perl-${PERL_VER} &&\
    ./Configure -des -Dprefix=/opt/apps/perl && make install

RUN  export PCIUTILS_VER=3.4.0 && cd / && curl -LO ftp://atrey.karlin.mff.cuni.cz/pub/linux/pci/pciutils-${PCIUTILS_VER}.tar.gz &&\
    tar xvf pciutils-${PCIUTILS_VER}.tar.gz && cd pciutils-${PCIUTILS_VER} &&\
    make && make PREFIX= DESTDIR=/opt/apps/green  install


#http://libguestfs.org/download/1.31-development/libguestfs-1.31.30.tar.gz

RUN     apt-get install -y libusb-1.0-0 libusb-1.0-0-dev libudev1 libudev-dev &&\
        git clone https://github.com/gregkh/usbutils.git &&\
        cp /usr/lib/x86_64-linux-gnu/libusb*.so /opt/apps/green/lib &&\
        cp /usr/lib/x86_64-linux-gnu/libudev*.so /opt/apps/green/lib &&\
	      cd usbutils && git submodule init && git submodule update &&\
	      ./autogen.sh --prefix=/opt/apps/green &&\
	      make && make install

RUN  apt-get update -y &&\
     apt-get -y install gcc libffi-dev libssl-dev python2.7 python2.7-dev  &&\
     ln -s /opt/apps/python2 /opt/python2

# ==== pipework in green ====
RUN  cd /opt/apps/green/bin &&  curl -LO https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework &&\
     chmod +x pipework

#RUN  apt-get update -y && apt-get install -y bridge-utils openvswitch-switch &&\
#     cp /sbin/brctl /opt/apps/green/bin/ &&\
#     cp `which ovs-vsctl` /opt/apps/green/bin/ &&\
#     cp `which truncate` /opt/apps/green/bin/


# green_app/gdrive
# https://github.com/prasmussen/gdrive
#RUN curl -L https://docs.google.com/uc?id=0B3X9GlR6EmbnQ0FtZmJJUXEyRTA\&export=download > /opt/apps/green/bin/gdrive &&\
#   ls /opt/apps/green/bin/gdrive ; chmod +x /opt/apps/green/bin/gdrive

# green_app/dbxcli - dropbox client
# ne treba imamo rclone
#ENV DROPBOX_VER=1.4.0
#RUN curl -LO https://github.com/dropbox/dbxcli/releases/download/v${DROPBOX_VER}/dbxcli-linux-amd64 &&\
#    mv dbxcli-linux-amd64 /opt/apps/green/bin/dbxcli && chmod +x /opt/apps/green/bin/dbxcli


RUN  curl -LO https://github.com/ncw/rclone/releases/download/v1.36/rclone-v1.36-linux-amd64.zip &&\
     unzip rclone-v*-linux-amd64.zip &&\
     chmod +x rclone-*linux-amd64/rclone &&\
     mv rclone*-linux-amd64/rclone /opt/apps/green/bin/

ENV FRP_VER 0.9.3
RUN  curl -LO https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_linux_amd64.tar.gz &&\
     tar xf frp*.tar.gz &&\
     cd frp_*linux_amd64/ &&\
     chmod +x frps frpc &&\
     mv frps frpc /opt/apps/green/bin/


ENV TCL_REPO_BASE=http://tinycorelinux.net/7.x/x86_64
ENV TCZ_DEPS_DEV    curl-dev \
                    openssl-dev \
                    ncurses-dev \
                    ncurses \
                    expat2-dev \
                    readline-dev \
                    libxml2-dev

ENV ROOTFS=/
# Install the base tiny linux build
RUN for dep in $TCZ_DEPS_DEV ; do \
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


ENV ROOTFS=/opt/apps/green
ENV TCL_REPO_BASE=http://tinycorelinux.net/7.x/x86_64
ENV TCZ_DEPS_GREEN  \
                    nfs-utils tcp_wrappers portmap rpcbind libtirpc \
                    htop ncurses-utils ncurses-terminfo \
                    git expat2 \
                    patch pcre \
                    parted liblvm2 \
                    strace glib2 libtirpc \
                    procps \
                    nfs-utils tcp_wrappers portmap rpcbind libtirpc \
                    bind-utilities libxml2 \
                    libpcap libnl tcpdump \
                    cifs-utils \
                    fuse libffi \
                    nss nspr sqlite3 libnotify \
                    groff \
                    iftop util-linux \
                    icu icu-bin \
                    man-pages man-db \
                    coreutils

#nss,nspr,sqlite3,libnotify - deps for electron applications ( atom, code )
#groff - aws deps

# Install the base tiny linux build
RUN for dep in $TCZ_DEPS_GREEN ; do \
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


RUN git clone https://github.com/relan/exfat.git &&\
    cd exfat && autoreconf --install &&\
    ./configure --prefix=/opt/apps/green &&\
    make &&\
    make install &&\
    mkdir -p /opt/apps/green/bin ;\
    mv /opt/apps/green/sbin/* /opt/apps/green/bin/



RUN  curl -LO http://www.harding.motd.ca/autossh/autossh-1.4e.tgz &&\
      tar xf autossh-1.4e.tgz &&\
      cd autossh-1.4e &&\
      ./configure --prefix=/opt/apps/green &&\
      make && make install


RUN apt-get -y install libgnutls28-dev bzip2 make gettext texinfo gnutls-bin &&\
    gpg --recv-keys --keyserver pgp.mit.edu  0x4F25E3B6 0xE0856959 0x33BD3F06 0x7EFD60D9 0xF7E48EDB

ENV PATH="/opt/apps/green/bin:$PATH"

RUN wget -c ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.26.tar.gz && \
    wget -c ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.26.tar.gz.sig && \
    gpg --verify libgpg-error-1.26.tar.gz.sig && tar -xzf libgpg-error-1.26.tar.gz && \
    cd libgpg-error-1.26/ && ./configure --prefix=/opt/apps/green && make && make install

RUN ls /opt/apps/green/lib ; ls /opt/apps/green/include &&\
    wget -c ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.7.6.tar.gz && \
    wget -c ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.7.6.tar.gz.sig && \
    gpg --verify libgcrypt-1.7.6.tar.gz.sig && tar -xzf libgcrypt-1.7.6.tar.gz && \
    cd libgcrypt-1.7.6 && ./configure CFLAGS="-I/opt/apps/green/include" LD_LIBRARY_PATH="/opt/apps/green/lib:$LD_LIBRARY_PATH" LDFLAGS="-L/opt/apps/green/lib" --prefix=/opt/apps/green  && make && make install

RUN wget -c ftp://ftp.gnupg.org/gcrypt/libassuan/libassuan-2.4.3.tar.bz2 && \
    wget -c ftp://ftp.gnupg.org/gcrypt/libassuan/libassuan-2.4.3.tar.bz2.sig && \
    gpg --verify libassuan-2.4.3.tar.bz2.sig && tar -xjf libassuan-2.4.3.tar.bz2 && \
    cd libassuan-2.4.3 && ./configure --prefix=/opt/apps/green && make && make install

RUN wget -c  ftp://ftp.gnupg.org/gcrypt/libksba/libksba-1.3.5.tar.bz2 && \
    wget -c ftp://ftp.gnupg.org/gcrypt/libksba/libksba-1.3.5.tar.bz2.sig && \
    gpg --verify libksba-1.3.5.tar.bz2.sig && tar -xjf libksba-1.3.5.tar.bz2 && \
    cd libksba-1.3.5 && ./configure --prefix=/opt/apps/green && make && make install

RUN wget -c ftp://ftp.gnupg.org/gcrypt/npth/npth-1.3.tar.bz2 && \
    wget -c ftp://ftp.gnupg.org/gcrypt/npth/npth-1.3.tar.bz2.sig && \
    gpg --verify npth-1.3.tar.bz2.sig && tar -xjf npth-1.3.tar.bz2 && \
    cd npth-1.3 && ./configure --prefix=/opt/apps/green && make && make install

RUN wget -c ftp://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz && \
    wget -c ftp://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz.sig && \
    gpg --verify ncurses-6.0.tar.gz.sig && tar -xzf ncurses-6.0.tar.gz && \
    cd ncurses-6.0 && export CPPFLAGS="$CPPFLAGS -P" && ./configure --prefix=/opt/apps/green && make && make install

RUN wget -c ftp://ftp.gnupg.org/gcrypt/pinentry/pinentry-1.0.0.tar.bz2 && \
   wget -c ftp://ftp.gnupg.org/gcrypt/pinentry/pinentry-1.0.0.tar.bz2.sig && \
   gpg --verify pinentry-1.0.0.tar.bz2.sig && tar -xjf pinentry-1.0.0.tar.bz2 && \
   cd pinentry-1.0.0 && ./configure --prefix=/opt/apps/green  --enable-pinentry-curses --disable-pinentry-qt4 && \
   make && make install

RUN wget -c ftp://ftp.gnupg.org/gcrypt/gnupg/gnupg-2.1.18.tar.bz2 && \
    wget -c ftp://ftp.gnupg.org/gcrypt/gnupg/gnupg-2.1.18.tar.bz2.sig && \
    gpg --verify gnupg-2.1.18.tar.bz2.sig && tar -xjf gnupg-2.1.18.tar.bz2 && \
    cd gnupg-2.1.18 && ./configure --prefix=/opt/apps/green  && make && make install

# ====================================== remove what we don't need  ==============================

RUN mkdir -p /opt/apps/green/bin ;\
    mkdir -p /opt/apps/green/lib ;\
    mkdir -p /opt/apps/green/share ;\
    cp -av /opt/apps/green/usr/local/bin/* /opt/apps/green/bin/ &&\
    cp -av /opt/apps/green/usr/local/sbin/* /opt/apps/green/bin/ &&\
    cp -av /opt/apps/green/usr/local/lib/* /opt/apps/green/lib/ &&\
    cp -av /opt/apps/green/usr/local/share/* /opt/apps/green/share/ &&\
    rm -rf /opt/apps/green/usr



RUN rm -rf /opt/apps/green/bin/git-cvsserver &&\
    rm -rf /opt/apps/green/lib/git-core/git-cvs* &&\
    rm -rf /opt/apps/green/lib/git-core/git-svn* &&\
    rm -rf /opt/apps/green/lib/git-core/git-web--browse*

# erase tcpdump.4.8.1
RUN rm -rf /opt/apps/green/bin/tcpdump.*

# erase static libraries, includes in /opt/apps/green
RUN rm /opt/apps/green/lib/*.a &&\
    rm /opt/apps/green/lib/*.la && echo green_apps removing static libraries
RUN rm -rf /opt/apps/green/include/ ; echo green_apps removing include files

RUN rm -rf /opt/apps/green/share/terminfo /opt/apps/green/share/git-gui /opt/apps/green/share/applications
RUN mv /opt/apps/green/sbin/* /opt/apps/green/bin/ ; rmdir /opt/apps/green/sbin
RUN echo "/opt/apps/green:" && ls -l /opt/apps/green
RUN rm -rf /opt/apps/go/test ; echo rm golang test directory


# manuals out
RUN rm -rf /opt/apps/green/man /opt/apps/green/share/doc /opt/apps/green/share/man ;\
    rm -rf /opt/apps/green/usr /opt/apps/green/var

RUN ls -ld /opt/apps/green/* ; ls -l /opt/apps/green/bin/ ; ls -l /opt/apps/green/lib/
# collect shared libraries needed for green apps execution


COPY extract_so_deps_green.sh /
RUN bash  /extract_so_deps_green.sh
