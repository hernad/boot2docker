FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN apt-get update

# ================= /opt/apps/green =========================================================

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
RUN curl -L -o openvpn-${OPENVPN_VER}.tar.gz https://github.com/OpenVPN/openvpn/archive/v${OPENVPN_VER}.tar.gz  &&\
    tar -xf openvpn-${OPENVPN_VER}.tar.gz

RUN cd openvpn-${OPENVPN_VER} && libtoolize --force && aclocal && autoheader && automake --force-missing --add-missing


RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list
RUN apt-get update -y && apt-get build-dep openvpn -y



RUN curl -LO http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz &&\
    tar xvf lzo-2.10.tar.gz && cd lzo-* && ./configure --prefix=/opt/apps/green &&\
    make install

RUN apt-get install net-tools -y

RUN cd openvpn-${OPENVPN_VER} &&\
    autoconf &&\
    ls /opt/apps/green/include/lzo &&\
    ./configure --prefix=/opt/apps/green CFLAGS="-I/opt/apps/green/include" LDFLAGS="-L/opt/apps/green/lib" OPENSSL_LIBS="-L/opt/apps/green/lib -lssl -lcrypto" OPENSSL_CFLAGS="-I/opt/apps/green/include" --disable-debug --disable-dependency-tracking --disable-silent-rules --with-crypto-library=openssl &&\
    make &&\
    make install

