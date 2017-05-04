FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list
RUN apt-get update -y


# ================= /opt/apps/python2 =========================================================


ENV CPPFLAGS="-I/opt/apps/python2/include" CFLAGS="-I/opt/apps/python2/include" LDFLAGS="-L/opt/apps/python2/lib"

# ====== python2 ==============
# https://pypi.python.org/pypi/pip
# https://github.com/docker-library/python/blob/master/2.7/wheezy/Dockerfile
# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG=C.UTF-8 PYTHON_VERSION=2.7.13 PYTHON_PIP_VERSION=9.0.1

ENV PATH  /opt/apps/python2/bin:$PATH

RUN apg-get -y build-dep python

# gpg: key 18ADD4FF: public key "Benjamin Peterson <benjamin@python.org>" imported
RUN gpg --keyserver pgp.mit.edu --recv-keys C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF &&\
    apt-get purge -y python.* &&\
    apt-get install -y bzip2 libbz2-dev &&\
    set -x \
        && mkdir -p /usr/src/python \
        && curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
        && curl -SL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
        && gpg --verify python.tar.xz.asc \
        && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
        && rm python.tar.xz* \
        && cd /usr/src/python \
        && ./configure --prefix=/opt/apps/python2 --enable-shared --enable-unicode=ucs4 \
        && make -j$(nproc) \
        && make install

ENV  LD_LIBRARY_PATH=/opt/apps/python2/lib
RUN     curl -SL 'https://bootstrap.pypa.io/get-pip.py' | python2 \
        && pip install --no-cache-dir --upgrade pip==$PYTHON_PIP_VERSION \
        && find /usr/local \
                \( -type d -a -name test -o -name tests \) \
                -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
                -exec rm -rf '{}' + \
        && rm -rf /usr/src/python \
        && pip install --no-cache-dir virtualenv readline

