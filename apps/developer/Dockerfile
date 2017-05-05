FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list
RUN apt-get update -y


# ================= /opt/apps/green =========================================================


RUN apt-get build-dep libpam-google-authenticator -y
ENV CPPFLAGS="-I/opt/apps/developer/include" CFLAGS="-I/opt/apps/developer/include" LDFLAGS="-L/opt/apps/developer/lib"


RUN curl -L https://sourceforge.net/projects/pamtester/files/latest/download?source=typ_redirect > pamtester.tar.gz &&\
    ls -lh pamtester.tar.gz &&\
    tar xf pamtester.tar.gz && cd pamtester* &&\
    ./configure CFLAGS="-I/opt/apps/developer/include" LDFLAGS="-L/opt/apps/developer/lib" --prefix=/opt/apps/developer &&\
    make &&\
    make install

ENV GCC_VER=7.1.0
ENV MAKE_VER=4.2.1

RUN apt-get build-dep make -y
RUN curl -s -LO http://ftp.gnu.org/gnu/make/make-${MAKE_VER}.tar.gz &&\
    tar xf make-${MAKE_VER}.tar.gz && cd make-${MAKE_VER} &&\
    ./configure CFLAGS=" -I/opt/apps/developer/include" LDFLAGS="-L/opt/apps/developer/lib" --prefix=/opt/apps/developer &&\
    make &&\
    make install


RUN curl -s -LO http://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.bz2 &&\
    tar xf gcc-${GCC_VER}.tar.bz2 && cd gcc-${GCC_VER} &&\
    ./contrib/download_prerequisites &&\
    ./configure \
       --disable-multilib \
       --enable-languages=c,c++ \
       CFLAGS=" -I/opt/apps/developer/include" LDFLAGS="-L/opt/apps/developer/lib" --prefix=/opt/apps/developer &&\
    make &&\
    make install


