FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN apt-get update


# /opt/apps/x11/share/{xcb,locale}
RUN echo "X11 `ls -ld /usr/share/X11/*`"  && mkdir -p /opt/apps/x11/share ; cp -av /usr/share/X11/* /opt/apps/x11/share/ &&\
   rm -rf $ROOTFS/usr/local/share/X11  &&\
   rm -rf /opt/apps/x11/lib/libdrm_*  # exclude drm drivers


# collect shared libraries needed for x11 execution
COPY extract_so_deps_x11.sh /
RUN bash  /extract_so_deps_x11.sh


