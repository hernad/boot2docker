FROM greenbox:for_apps

ARG DOCKER_PROXY=172.17.0.4

RUN echo "docker proxy: $DOCKER_PROXY" \
 && echo "Acquire::HTTP::Proxy \"http://$DOCKER_PROXY:3142\";" > /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy

RUN apt-get update -y


ENV TCZ_DEPS_X    Xorg-7.7-bin libpng libXau libXaw  libXext libxcb libXdmcp libX11 libICE libXt libSM libXmu aterm \
                  libXcursor libXrender libXinerama libGL libXdamage libXfixes libXxf86vm libxshmfence libdrm \
                  libXfont freetype harfbuzz fontconfig Xorg-fonts dbus

RUN for dep in $TCZ_DEPS_X ; do \
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


RUN cd / && curl -sLO $TCL_REPO_BASE/tcz/Xorg-7.7-bin.tcz.list &&\
       ( [ -d /opt/apps/x11/bin ] || mkdir -p /opt/apps/x11/bin ) &&\
       ( [ -d /opt/apps/x11/lib ] || mkdir -p /opt/apps/x11/lib ) &&\
       while read FILE ; do case $FILE in \
                              *\/bin\/*) mv $ROOTFS/$FILE /opt/apps/x11/bin ;; \
                              *\/lib\/*) mv $ROOTFS/$FILE /opt/apps/x11/lib ;; \
    		   esac ; done < Xorg-7.7-bin.tcz.list &&\
       cd $ROOTFS/usr/local/lib && \
       mv libpng* libXau* libxcb* libXdmcp* libX11* libICE* libXt* libSM* libXmu* libXcursor* libdrm* libXfont* \
             /opt/apps/x11/lib
             
# /opt/apps/x11/share/{xcb,locale}
RUN echo "X11 `ls -ld /usr/share/X11/*`"  && mkdir -p /opt/apps/x11/share ; cp -av /usr/share/X11/* /opt/apps/x11/share/ &&\
   rm -rf $ROOTFS/usr/local/share/X11  &&\
   rm -rf /opt/apps/x11/lib/libdrm_*  # exclude drm drivers


# collect shared libraries needed for x11 execution
COPY extract_so_deps_x11.sh /
RUN bash  /extract_so_deps_x11.sh
