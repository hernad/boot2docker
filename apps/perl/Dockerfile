FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list
RUN apt-get update -y

ENV APPS_DIR=/opt/apps/perl
ENV CPPFLAGS="-I${APPS_DIR}/include" CFLAGS="-I${APPS_DIR}/include" LDFLAGS="-L${APPS_DIR}/lib"


# perl-5.24.1.tar.xz	14-Jan-2017 12:05	11M
RUN export PERL_VER=5.24.1 && cd / && curl -sLO http://www.cpan.org/src/5.0/perl-${PERL_VER}.tar.xz &&\
    tar xf perl-${PERL_VER}.tar.xz &&  cd perl-${PERL_VER} &&\
    ./Configure -des -Dprefix=${APPS_DIR} && make install
