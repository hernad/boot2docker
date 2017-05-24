FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

ENV APPS_DIR=/opt/apps/developer
RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list
RUN apt-get update -y

# ================= /opt/apps/developer =========================================================

RUN apt-get build-dep libpam-google-authenticator -y
ENV CPPFLAGS="-I$APPS_DIR/include" CFLAGS="-I$APPS_DIR/include" LDFLAGS="-L$APPS_DIR/lib"


RUN curl -L https://sourceforge.net/projects/pamtester/files/latest/download?source=typ_redirect > pamtester.tar.gz &&\
    ls -lh pamtester.tar.gz &&\
    tar xf pamtester.tar.gz && cd pamtester* &&\
    ./configure CFLAGS="-I$APPS_DIR/include" LDFLAGS="-L$APPS_DIR/lib" --prefix=$APPS_DIR &&\
    make &&\
    make install

ENV GCC_VER=7.1.0
ENV MAKE_VER=4.2.1

#RUN apt-get build-dep make -y
#RUN curl -s -LO http://ftp.gnu.org/gnu/make/make-${MAKE_VER}.tar.gz &&\
#    tar xf make-${MAKE_VER}.tar.gz && cd make-${MAKE_VER} &&\
#    ./configure CFLAGS=" -I$APPS_DIR/include" LDFLAGS="-L$APPS_DIR/lib" --prefix=$APPS_DIR &&\
#    make &&\
#    make install


#RUN curl -s -LO http://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2 &&\
#    tar xf gcc-${GCC_VER}.tar.bz2 && cd gcc-${GCC_VER} &&\
#    ./contrib/download_prerequisites &&\
#    ./configure \
#       --disable-multilib \
#       --enable-languages=c,c++ \
#       CFLAGS=" -I$APPS_DIR/include" LDFLAGS="-L$APPS_DIR/lib" --prefix=$APPS_DIR &&\
#    make &&\
#    make make install-strip

# install -> $APPS_DIR
ENV ROOTFS=$APPS_DIR

ENV TCL_REPO_BASE=http://tinycorelinux.net/${TINYCORE_VER}/x86_64
ENV TCZ_DEPS_DEVELOER  \
    binutils \
    compiletc gcc make \
    cloog isl \
    mpc mpfr gmp \
    readline \
    gawk patch sed m4 grep bison flex pkg-config \
    acl attr \
    gcc_libs gcc_libs-dev glibc_base-dev glibc_add_lib \
    zlib_base-dev util-linux_base-dev e2fsprogs_base-dev \
    # ansible deps
    libffi-dev libffi \
    openssl-dev \
    gmp gmp-dev \
    postgresql-9.6-client readline6 postgresql-dev


RUN for dep in $TCZ_DEPS_DEVELOER ; do \
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


RUN mkdir -p $APPS_DIR/bin ;\
    mkdir -p $APPS_DIR/lib ;\
    mkdir -p $APPS_DIR/include ;\
    mkdir -p $APPS_DIR/share ;\
      # postgresql 9.6
      mv $APPS_DIR/usr/local/pgsql96/bin/*  $APPS_DIR/bin &&\
      mv $APPS_DIR/usr/local/pgsql96/lib/*  $APPS_DIR/lib &&\
        cp -av $APPS_DIR/usr/local/bin/*      $APPS_DIR/bin/ &&\
        cp -av $APPS_DIR/usr/local/lib/*      $APPS_DIR/lib/ &&\
        cp -av $APPS_DIR/usr/local/include/*  $APPS_DIR/include/ &&\
        cp -av $APPS_DIR/usr/local/share/*    $APPS_DIR/share/ &&\
        cp -av $APPS_DIR/usr/lib/*            $APPS_DIR/lib/ &&\
        cp -av $APPS_DIR/usr/include/*        $APPS_DIR/include/ &&\
        rm -rf $APPS_DIR/usr/local &&\
        rm -rf $APPS_DIR/usr




# linux x86 includes
RUN mkdir -p  $APPS_DIR/include/linux/x86/include/ &&\
    cp -av /usr/src/linux/arch/x86/include/* $APPS_DIR/include/linux/x86/include/ &&\
    mkdir -p $APPS_DIR/include/linux/include/ &&\
    cp -av /usr/src/linux/include/* $APPS_DIR/include/linux/include/


# ================= /opt/apps/python2 =========================================================
RUN cd /opt/apps &&\
    curl -sLO https://dl.bintray.com/hernad/greenbox/python2_2.7.13.tar.xz &&\
    tar xf python2_2.7.13.tar.xz && rm python2_2.7.13.tar.xz

RUN cd /opt/apps &&\
    curl -sLO https://dl.bintray.com/hernad/greenbox/green_4.1.2.tar.xz &&\
    tar xf green_4.1.2.tar.xz && rm green_4.1.2.tar.xz


#RUN cd / ; find -name "/rootfs/libpthread*so*"
#RUN cd / ; find -name "/rootfs/lib/libc*so*"

RUN mv /usr/include /usr/include.orig

#The uapi folder is supposed to contain the user space API of the kernel.
ENV CPPFLAGS="-I/opt/apps/green/include -I/opt/apps/python2/include -I$APPS_DIR/include -I$APPS_DIR/include/linux/x86/include -I$APPS_DIR/include/linux/x86/include/generated -I$APPS_DIR/include/linux/x86/include/uapi -I$APPS_DIR/include/linux/x86/include/generated/uapi -I$APPS_DIR/include/linux/include -I$APPS_DIR/include/linux/include/uapi" \
    CFLAGS="-I/opt/apps/green/include -I/opt/apps/python2/include -I$APPS_DIR/include -I$APPS_DIR/include/linux/x86/include -I$APPS_DIR/include/linux/x86/include/generated -I$APPS_DIR/include/linux/x86/include/uapi  -I$APPS_DIR/include/linux/x86/include/generated/uapi -I$APPS_DIR/include/linux/include -I$APPS_DIR/include/linux/include/uapi" \
    LDFLAGS="-L/opt/apps/green/lib -L/opt/apps/python2/lib -L$APPS_DIR/lib"

# skloniti libc.so, libpthread.so prave probleme kod ansible builda u unutar docker sesije
RUN mkdir /tmp/libs && \
    mv $APPS_DIR/lib/libpthread.* $APPS_DIR/lib/libc.so  $APPS_DIR/lib/libc.a /tmp/libs/


#    LDFLAGS="-L/opt/apps/green/lib -L/opt/apps/python2/lib -L$APPS_DIR/lib -nodefaultlibs -Wl,-rpath,/rootfs/lib64 -Wl,-dynamic-linker,/rootfs/lib/lib64/libc-2.24.so -Wl,-dynamic-linker,/rootfs/lib64/libpthread-2.24.so"

# ansible build dependencies libpthread.so.0
#RUN cp -av /rootfs/lib/*so* /opt/apps/python2/lib/
#RUN apt-get build-dep -y ansible

ENV LD_LIBRARY_PATH="/opt/apps/python2/lib" PATH="/opt/apps/python2/bin:/usr/bin:/bin:/usr/local/bin:/usr/sbin:/sbin"
RUN pip install --install-option="--prefix=$APPS_DIR" --no-cache-dir ansible

# vrati libc, libpthread
RUN cp -av /tmp/libs/*  $APPS_DIR/lib/

COPY apps/developer/set_developer_envars.sh $APPS_DIR/bin/
RUN chmod +x $APPS_DIR/bin/set_developer_envars.sh
