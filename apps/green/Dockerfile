FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN apt-get update

# ================= /opt/apps/green =========================================================


# == logrotate ==
ENV LOGROTATE_VER=3.10.0
RUN apt-get install -y libpopt-dev
RUN curl -k -LO https://github.com/logrotate/logrotate/releases/download/$LOGROTATE_VER/logrotate-$LOGROTATE_VER.tar.gz &&\
   tar xvf logrotate-$LOGROTATE_VER.tar.gz &&\
   cd /logrotate-$LOGROTATE_VER &&\
   export LDFLAGS="-static" && ./configure --prefix=/opt/apps/green &&\
   make && make install &&  mkdir -p /opt/apps/green/bin && mv /opt/apps/green/sbin/* /opt/apps/green/bin &&\
   ls -lh /opt/apps/green/bin/logrotate


# === rsync ===
ENV RSYNC_VER=3.1.2
RUN mkdir -p /opt/apps/green/bin &&\
    cd / && curl -LO https://download.samba.org/pub/rsync/src/rsync-${RSYNC_VER}.tar.gz &&\
    tar xvf rsync-${RSYNC_VER}.tar.gz &&\
    cd /rsync-${RSYNC_VER} && ./configure && make && /usr/bin/install -c  -m 755 rsync /opt/apps/green/bin

# Pipe Viewer - is a terminal-based tool for monitoring the progress of data through a pipeline.
RUN curl -LO http://www.ivarch.com/programs/sources/pv-1.6.0.tar.gz  &&\
    tar xvf pv-1.6.0.tar.gz  &&\
    cd /pv-1.6.0 && ./configure && make && /usr/bin/install -c pv /opt/apps/green/bin

# == qperf =====
RUN cd /tmp && curl -LO https://www.openfabrics.org/downloads/qperf/qperf-0.4.9.tar.gz &&\
    tar xvf qperf-0.4.9.tar.gz &&\
    cd /tmp/qperf-0.4.9 && sh autogen.sh && \
    ./configure && make && /usr/bin/install -c src/qperf /opt/apps/green/bin &&\
    cd /tmp && rm qperf-0.4.9.tar.gz && rm -r -f qperf-0.4.9


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

# ---------- fio http://jrs-s.net/2015/11/23/fio-cheat-sheet/ ------------
RUN git clone git://git.kernel.dk/fio.git &&\
    cd fio && ./configure --prefix=/opt/apps/green &&\
    make install

# ==== mbuffer =========
#Version 20151002 md5=b2d20c4d880518c5fb8f8db734962f45
# http://www.maier-komor.de/software/mbuffer/mbuffer-20151002.tgz
RUN export MBUFFER_VER="20151002" && echo "mbuffer ver: $MBUFFER_VER" && curl -LO http://www.maier-komor.de/software/mbuffer/mbuffer-${MBUFFER_VER}.tgz &&\
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

RUN export PERL_VER=5.24.0 && cd / && curl -LO http://www.cpan.org/src/5.0/perl-${PERL_VER}.tar.gz &&\
    tar xvf perl-${PERL_VER}.tar.gz &&  cd perl-${PERL_VER} &&\
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

RUN  apt-get update -y && apt-get install -y bridge-utils openvswitch-switch &&\
     cp /sbin/brctl /opt/apps/green/bin/ &&\
     cp `which ovs-vsctl` /opt/apps/green/bin/ &&\
     cp `which truncate` /opt/apps/green/bin/


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
                    man-pages man-db


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



ENV OPENVPN_VER=2.4.1
#RUN apt-get build-dep openvpn -y
RUN curl -L -o openvpn-${OPENVPN_VER}.tar.gz https://github.com/OpenVPN/openvpn/archive/v${OPENVPN_VER}.tar.gz  &&\
    tar -xf openvpn-${OPENVPN_VER}.tar.gz &&\
    cd openvpn-${OPENVPN_VER} &&\
    autoconf &&\
    ./configure --prefix=/opt/apps/green &&\
    make &&\
    make install


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

RUN rm -rf /opt/apps/green/usr

# collect shared libraries needed for green apps execution
COPY extract_so_deps_green.sh /
RUN bash  /extract_so_deps_green.sh
