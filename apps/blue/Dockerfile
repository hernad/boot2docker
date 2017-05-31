FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4
ARG KERNEL_VERSION=4.11.3

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list
RUN apt-get update -y

ENV APPS_DIR=/opt/apps/blue
ENV CPPFLAGS="-I${APPS_DIR}/include" CFLAGS="-I${APPS_DIR}/include" LDFLAGS="-L${APPS_DIR}/lib"

# ================= /opt/apps/blue =========================================================

ENV XNBD_VER=0.4.0
RUN apt-get build-dep -y xnbd && apt-get -y install libjansson-dev &&\
    curl -sLO https://bitbucket.org/hirofuchi/xnbd/downloads/xnbd-${XNBD_VER}.tgz &&\
    tar xf xnbd-${XNBD_VER}.tgz &&\
    cd xnbd-${XNBD_VER}/trunk &&\
    ls -l * && autoreconf -i &&\
    ./configure CFLAGS="-I${APPS_DIR}/include" LDFLAGS="-L${APPS_DIR}/lib" --prefix=${APPS_DIR} &&\
    make


RUN curl -sLO http://downloads.es.net/pub/iperf/iperf-3-current.tar.gz &&\
        tar xf iperf-3*.tar.gz && rm iperf-3*.tar.gz && cd iperf* &&\
        ./configure CFLAGS="-I${APPS_DIR}/include" LDFLAGS="-L${APPS_DIR}/lib" --prefix=${APPS_DIR} &&\
        make &&\
        make install


# == qperf 0.4.9, 2012-11-07 ===
RUN cd /tmp && curl -sLO https://www.openfabrics.org/downloads/qperf/qperf-0.4.9.tar.gz &&\
            tar xvf qperf-0.4.9.tar.gz &&\
            cd /tmp/qperf-0.4.9 && sh autogen.sh && \
            ./configure && make && /usr/bin/install -c src/qperf ${APPS_DIR}/bin &&\
            cd /tmp && rm qperf-0.4.9.tar.gz && rm -r -f qperf-0.4.9

# ---------- fio http://jrs-s.net/2015/11/23/fio-cheat-sheet/ ------------
# fio - Flexible IO Tester
# http://git.kernel.dk/?p=fio.git;a=summary,  last change	Sat, 8 Apr 2017 19:04:21 +0200 (11:04 -0600)
RUN git clone git://git.kernel.dk/fio.git &&\
          cd fio && ./configure --prefix=${APPS_DIR} &&\
          make install


# ==== ag - the silver searcher ===========
RUN  apt-get install -y automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev &&\
               cd / ; git clone https://github.com/ggreer/the_silver_searcher.git &&\
               cd the_silver_searcher && export LDFLAGS="-static" && ./build.sh --prefix=${APPS_DIR} &&\
               make install

RUN apt-get build-dep -y jq &&\
              git clone https://github.com/stedolan/jq.git &&\
             cd jq &&\
             git submodule update --init &&\
             autoreconf -i  &&\
             ./configure --prefix=${APPS_DIR}   --disable-valgrind --enable-all-static  --disable-docs   &&\
             make &&\
             ls -l &&\
             chmod +x jq && cp jq ${APPS_DIR}/bin


# ==== mbuffer =========
# Version 20161115 md5=b81940da5b750c6adda65dfbf8b2ad36
# http://www.maier-komor.de/software/mbuffer/mbuffer-20161115.tgz
# http://www.maier-komor.de/mbuffer.html
RUN export MBUFFER_VER="20161115" && echo "mbuffer ver: $MBUFFER_VER" && curl -LO http://www.maier-komor.de/software/mbuffer/mbuffer-${MBUFFER_VER}.tgz &&\
              cd / && tar xvf mbuffer-${MBUFFER_VER}.tgz && cd mbuffer-${MBUFFER_VER} && ./configure --prefix=${APPS_DIR} &&\
              make install


# Pipe Viewer - is a terminal-based tool for monitoring the progress of data through a pipeline.
# pv 1.6.0, 15 Mar 2015
RUN curl -sLO http://www.ivarch.com/programs/sources/pv-1.6.0.tar.gz  &&\
                  tar xvf pv-1.6.0.tar.gz  &&\
                  cd /pv-1.6.0 && ./configure && make && /usr/bin/install -c pv ${APPS_DIR}/bin


# RUN curl -LO https://github.com/zfsonlinux/zfs-auto-snapshot/archive/master.zip &&\
#    unzip master.zip &&\
#    cd zfs-auto-snapshot-master && /usr/bin/install src/zfs-auto-snapshot.sh ${APPS_DIR}/bin/zfs-auto-snapshot


RUN git clone https://github.com/relan/exfat.git &&\
    cd exfat && autoreconf --install &&\
    ./configure --prefix=${APPS_DIR} &&\
    make &&\
    make install &&\
    mkdir -p ${APPS_DIR}/bin ;\
    mv ${APPS_DIR}/sbin/* ${APPS_DIR}/bin/


RUN apt-get -y install libgnutls28-dev bzip2 make gettext texinfo gnutls-bin &&\
    gpg --recv-keys --keyserver pgp.mit.edu  0x4F25E3B6 0xE0856959 0x33BD3F06 0x7EFD60D9 0xF7E48EDB

ENV PATH=/usr/local/bin:/bin:/usr/bin:${APPS_DIR}/bin

RUN curl -sLO ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.26.tar.gz && \
    curl -sLO ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.26.tar.gz.sig && \
    gpg --verify libgpg-error-1.26.tar.gz.sig && tar -xzf libgpg-error-1.26.tar.gz && \
    cd libgpg-error-1.26/ && ./configure --prefix=${APPS_DIR} && make && make install

RUN ls ${APPS_DIR}/lib ; ls ${APPS_DIR}/include &&\
    curl -sLO ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.7.6.tar.gz && \
    curl -sLO ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.7.6.tar.gz.sig && \
    gpg --verify libgcrypt-1.7.6.tar.gz.sig && tar -xzf libgcrypt-1.7.6.tar.gz && \
    cd libgcrypt-1.7.6 && ./configure CFLAGS="-I${APPS_DIR}/include" LD_LIBRARY_PATH="${APPS_DIR}/lib:$LD_LIBRARY_PATH" LDFLAGS="-L${APPS_DIR}/lib" --prefix=${APPS_DIR}  && make && make install

RUN curl -sLO ftp://ftp.gnupg.org/gcrypt/libassuan/libassuan-2.4.3.tar.bz2 && \
    curl -sLO ftp://ftp.gnupg.org/gcrypt/libassuan/libassuan-2.4.3.tar.bz2.sig && \
    gpg --verify libassuan-2.4.3.tar.bz2.sig && tar -xjf libassuan-2.4.3.tar.bz2 && \
    cd libassuan-2.4.3 && ./configure --prefix=${APPS_DIR} && make && make install

RUN curl -sLO ftp://ftp.gnupg.org/gcrypt/libksba/libksba-1.3.5.tar.bz2 && \
    curl -sLO ftp://ftp.gnupg.org/gcrypt/libksba/libksba-1.3.5.tar.bz2.sig && \
    gpg --verify libksba-1.3.5.tar.bz2.sig && tar -xjf libksba-1.3.5.tar.bz2 && \
    cd libksba-1.3.5 && ./configure --prefix=${APPS_DIR} && make && make install

RUN curl -sLO ftp://ftp.gnupg.org/gcrypt/npth/npth-1.3.tar.bz2 && \
    curl -sLO ftp://ftp.gnupg.org/gcrypt/npth/npth-1.3.tar.bz2.sig && \
    gpg --verify npth-1.3.tar.bz2.sig && tar -xjf npth-1.3.tar.bz2 && \
    cd npth-1.3 && ./configure --prefix=${APPS_DIR} && make && make install

RUN curl -sLO ftp://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz && \
    curl -sLO ftp://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz.sig && \
    gpg --verify ncurses-6.0.tar.gz.sig && tar -xzf ncurses-6.0.tar.gz && \
    cd ncurses-6.0 && export CPPFLAGS="$CPPFLAGS -P" && ./configure --prefix=${APPS_DIR} && make && make install

RUN curl -sLO ftp://ftp.gnupg.org/gcrypt/pinentry/pinentry-1.0.0.tar.bz2 && \
    curl -sLO ftp://ftp.gnupg.org/gcrypt/pinentry/pinentry-1.0.0.tar.bz2.sig && \
    gpg --verify pinentry-1.0.0.tar.bz2.sig && tar -xjf pinentry-1.0.0.tar.bz2 && \
    cd pinentry-1.0.0 && ./configure --prefix=${APPS_DIR}  --enable-pinentry-curses --disable-pinentry-qt4 && \
    make && make install

RUN curl -sLO ftp://ftp.gnupg.org/gcrypt/gnupg/gnupg-2.1.18.tar.bz2 && \
    curl -sLO ftp://ftp.gnupg.org/gcrypt/gnupg/gnupg-2.1.18.tar.bz2.sig && \
    gpg --verify gnupg-2.1.18.tar.bz2.sig && tar -xjf gnupg-2.1.18.tar.bz2 && \
    cd gnupg-2.1.18 && ./configure --prefix=${APPS_DIR}  && make && make install


ENV ROOTFS=${APPS_DIR}
ENV TCL_REPO_BASE=http://tinycorelinux.net/${TINYCORE_VER}/x86_64
ENV TCZ_DEPS_BLUE  \
         strace glib2 libtirpc \
         nfs-utils tcp_wrappers portmap rpcbind libtirpc \
         # libpcap ima u green
         libnl tcpdump \
         #nss,nspr,sqlite3,libnotify - deps for electron applications ( atom, code )
         nss nspr sqlite3 libnotify \
         #groff - aws deps
         groff \
         iftop util-linux \
         icu icu-bin \
         coreutils \
         cifs-utils

#man-db

# Install the base tiny linux build
RUN for dep in $TCZ_DEPS_BLUE ; do \
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

ENV KERNELDIR=/usr/src/linux

ENV PATH="/usr/bin:/bin:/usr/local/bin:/usr/sbin:/sbin"
RUN apt-get -y install cmake &&\
        mkdir -p /lib/modules/$(uname -r)/build &&\
        mkdir -p ${APPS_DIR}/kernel/modules/$KERNEL_VERSION-$LINUX_BRAND &&\
        git clone https://github.com/draios/sysdig.git && cd sysdig &&\
        mkdir build && cd build &&\
        cmake -DCMAKE_INSTALL_PREFIX=${APPS_DIR} .. &&\
        make &&\
        make install &&\
        cp driver/sysdig-probe.ko ${APPS_DIR}/kernel/modules/$KERNEL_VERSION-$LINUX_BRAND


# === python2 app install ===

RUN cd /opt/apps &&\
    curl -sLO https://dl.bintray.com/hernad/greenbox/python2_2.7.13.tar.xz &&\
    tar xf python2_2.7.13.tar.xz && rm python2_2.7.13.tar.xz

RUN cd /opt/apps &&\
    curl -sLO https://dl.bintray.com/hernad/greenbox/green_4.1.2.tar.xz &&\
    tar xf green_4.1.2.tar.xz && rm green_4.1.2.tar.xz

RUN mv /usr/include /usr/include.orig

#The uapi folder is supposed to contain the user space API of the kernel.
ENV CPPFLAGS="-I/opt/apps/green/include -I/opt/apps/python2/include -I$APPS_DIR/include -I$APPS_DIR/include/linux/x86/include -I$APPS_DIR/include/linux/x86/include/generated -I$APPS_DIR/include/linux/x86/include/uapi -I$APPS_DIR/include/linux/x86/include/generated/uapi -I$APPS_DIR/include/linux/include -I$APPS_DIR/include/linux/include/uapi" \
    CFLAGS="-I/opt/apps/green/include -I/opt/apps/python2/include -I$APPS_DIR/include -I$APPS_DIR/include/linux/x86/include -I$APPS_DIR/include/linux/x86/include/generated -I$APPS_DIR/include/linux/x86/include/uapi  -I$APPS_DIR/include/linux/x86/include/generated/uapi -I$APPS_DIR/include/linux/include -I$APPS_DIR/include/linux/include/uapi" \
    LDFLAGS="-L/opt/apps/green/lib -L/opt/apps/python2/lib -L$APPS_DIR/lib"

# skloniti libc.so, libpthread.so prave probleme kod ansible builda u unutar docker sesije
# RUN mkdir /tmp/libs && \
#    mv $APPS_DIR/lib/libpthread.* $APPS_DIR/lib/libc.so  $APPS_DIR/lib/libc.a /tmp/libs/

ENV LD_LIBRARY_PATH="/opt/apps/python2/lib" PATH="/opt/apps/python2/bin:/usr/bin:/bin:/usr/local/bin:/usr/sbin:/sbin"
RUN pip install --install-option="--prefix=$APPS_DIR" --no-cache-dir speedtest-cli

# vrati libc, libpthread
# RUN cp -av /tmp/libs/*  $APPS_DIR/lib/



# ====================================== remove what we don't need  ==============================

RUN mkdir -p ${APPS_DIR}/bin ;\
    mkdir -p ${APPS_DIR}/lib ;\
    mkdir -p ${APPS_DIR}/share ;\
        cp -av ${APPS_DIR}/usr/local/bin/* ${APPS_DIR}/bin/ &&\
        cp -av ${APPS_DIR}/usr/local/sbin/* ${APPS_DIR}/bin/ &&\
        cp -av ${APPS_DIR}/usr/local/lib/* ${APPS_DIR}/lib/ &&\
        cp -av ${APPS_DIR}/usr/local/share/* ${APPS_DIR}/share/ &&\
        #/usr/local/etc/init.d/nfs-client /usr/local/etc/init.d/nfs-server
        cp -av ${APPS_DIR}/usr/local/etc/init.d/* ${APPS_DIR}/bin/ &&\
        rm -rf ${APPS_DIR}/usr &&\
        # erase static libraries, includes in ${APPS_DIR}
        rm ${APPS_DIR}/lib/*.a &&\
        rm ${APPS_DIR}/lib/*.la && echo blue_apps removing static libraries &&\
        rm -rf ${APPS_DIR}/include/ ; echo blue_apps removing include files &&\
        # manuals out
        rm -rf ${APPS_DIR}/man ${APPS_DIR}/share/doc ${APPS_DIR}/share/man ;\
        rm -rf ${APPS_DIR}/usr ${APPS_DIR}/var &&\
        rm -rf ${APPS_DIR}/share/gnupg/*.txt ; rm -rf ${APPS_DIR}/share/gitweb  ${APPS_DIR}/share/pixmaps &&\
        rm -rf ${APPS_DIR}/share/locale/* &&\
        rm -f "${APPS_DIR}/share/]" &&\
        rm -f "${APPS_DIR}/bin/["
