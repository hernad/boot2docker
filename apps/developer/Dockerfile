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


RUN curl https://downloads.sourceforge.net/project/pamtester/pamtester/0.1.2/pamtester-0.1.2.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fpamtester%2Ffiles%2Fpamtester%2F0.1.2%2F&ts=1493190552&use_mirror=kent > pamtester-0.1.2.tar.gz &&\
    tar xf pamtester*.tar.gz && cd pamtester* &&\
    ./configure CFLAGS="-I/opt/apps/developer/include" LDFLAGS="-L/opt/apps/developer/lib" --prefix=/opt/apps/developer &&\
    make &&\
    make install
