FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.2

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN apt-get update

# https://www.vagrantup.com/downloads.html
ENV VAGRANT_VER 1.9.1
RUN curl -k -LO https://releases.hashicorp.com/vagrant/${VAGRANT_VER}/vagrant_${VAGRANT_VER}_x86_64.deb &&\
    dpkg -i vagrant_${VAGRANT_VER}_x86_64.deb

RUN cd /opt/vagrant && rm -rf embedded/gems/gems/vagrant-$VAGRANT_VER/test

RUN mkdir -p /opt/vagrant/plugins

COPY vagrant_plugins/*  /opt/vagrant/plugins

RUN mv /opt/vagrant /opt/apps/vagrant



