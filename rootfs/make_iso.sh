#!/bin/sh

set -e

BOOT_DIR=/opt/boot

# Ensure init system invokes /opt/shutdown.sh on reboot or shutdown.
#  1) Find three lines with `useBusyBox`, blank, and `clear`
#  2) insert run op after those three lines
sed -i "1,/^useBusybox/ { /^useBusybox/ { N;N; /^useBusybox\n\nclear/ a\
\\\n\
# Run greenbox shutdown script\n\
test -x \"/opt/shutdown.sh\" && /opt/shutdown.sh\n
} }" $ROOTFS/etc/init.d/rc.shutdown
# Verify sed worked
grep -q "/opt/shutdown.sh" $ROOTFS/etc/init.d/rc.shutdown || ( echo "Error: failed to insert shutdown script into /etc/init.d/rc.shutdown"; exit 1 )

# Make some handy symlinks (so these things are easier to find)
ln -fs $BOOT_DIR/log/docker.log $ROOTFS/var/log/
ln -fs $BOOT_DIR/log/udhcp.log $ROOTFS/var/log/
ln -fs $BOOT_DIR/log/greenbox.log $ROOTFS/var/log/
#ln -fs $BOOT_DIR/log/wtmp $ROOTFS/var/log/

ln -fs $BOOT_DIR/etc/ld.so.cache $ROOTFS/etc/
ln -fs $BOOT_DIR/etc/dnsmasq.conf $ROOTFS/etc/
#ln -fs /usr/local/etc/init.d/docker $ROOTFS/etc/init.d/

# /bin/bash
ln -fs /usr/local/bin/bash $ROOTFS/bin/

# green apps
ln -fs /opt/green/bin/rsync $ROOTFS/usr/bin/rsync


# /usr/bin/python, /usr/bin/perl, /usr/bin/logrotate
ln -fs /opt/python2/bin/python $ROOTFS/usr/bin/ ; ln -fs /opt/python2/lib/libpython2.7.so.1.0 $ROOTFS/usr/lib/ # symlinks /usr/bin for ansible
ln -fs /opt/apps/perl/bin/perl $ROOTFS/usr/bin/perl  ; ln -fs /opt/apps/perl/bin/perl $ROOTFS/usr/local/bin/perl

ln -fs /opt/green/bin/logrotate $ROOTFS/usr/bin/

[ -d $ROOTFS/usr/local/etc/ssl ] && rm -rf $ROOTFS/usr/local/etc/ssl
[ -d $ROOTFS/etc/ssl ] && rm -rf $ROOTFS/etc/ssl
ln -fs /opt/boot/etc/ssl $ROOTFS/usr/local/etc/ssl # /usr/local/bin/curl needs this location
ln -fs /opt/boot/etc/ssl $ROOTFS/etc/ssl # docker golang needs /etc/ssl

ln -fs /opt/x11/bin/xauth $ROOTFS/usr/bin/
ln -fs /opt/x11/share $ROOTFS/usr/share/X11

#docker-machine wants /var/lib/boot2docker
ln -fs /opt/boot $ROOTFS/var/lib/boot2docker
ln -fs /usr/local/etc/init.d/docker $ROOTFS/etc/init.d/docker

# no includes in iso
rm -rf  $ROOTFS/usr/local/include $ROOTFS/usr/include

ln -fs /opt/developer/include $ROOTFS/usr/include

# gcc asks for this library archive here
ln -fs /opt/developer/lib/libc_nonshared.a $ROOTFS/usr/lib/libc_nonshared.a

# Setup /etc/os-release with some nice contents
NAME=greenbox
greenVersion="$(cat $ROOTFS/etc/sysconfig/greenbox)" # something like "1.1.0"
greenDetail="$(cat $ROOTFS/etc/sysconfig/greenbox_build)" # something like "master : 740106c - Tue Jul 29 03:29:25 UTC 2014"
tclVersion="$(cat $ROOTFS/usr/share/doc/tc/release.txt)" # something like "5.3"
cat > $ROOTFS/etc/os-release <<-EOOS
NAME=$NAME
VERSION=$greenVersion
ID=boot2docker
ID_LIKE=tcl
VERSION_ID=$greenVersion
PRETTY_NAME="greenbox $greenVersion (TCL $tclVersion); $greenDetail"
ANSI_COLOR="1;34"
HOME_URL="https://github.com/hernad/greenbox"
SUPPORT_URL="https://github.com/hernad/greenbox"
BUG_REPORT_URL="https://github.com/hernad/greenbox/issues"
EOOS

rm -rf $ROOTFS/usr/share/doc
rm -rf $ROOTFS/usr/share/man
rm -rf $ROOTFS/usr/share/i18n
rm -rf $ROOTFS/usr/share/locale
rm -rf $ROOTFS/usr/share/syslinux
rm -rf $ROOTFS/usr/share/tabeset
rm -rf $ROOTFS/usr/local/src
rm -rf $ROOTFS/usr/local/share/common-lisp
rm -rf $ROOTFS/usr/local/share/man
rm -rf $ROOTFS/usr/local/share/zfs
rm -rf $ROOTFS/usr/local/share/licenses
rm -rf $ROOTFS/usr/local/share/pkgconfig
rm -rf $ROOTFS/usr/local/share
# Pack the rootfs
cd $ROOTFS

#http://nairobi-embedded.org/initramfs_tutorial.html
#$ find . | cpio -H newc -o | gzip -9 > ../initrd.img-`uname -r`-custom

find | ( set -x; cpio -o -H newc | xz -6 --format=lzma --verbose --verbose ) > /tmp/iso/boot/initrd.img
#find | ( set -x; cpio -o -H newc | gzip -9 ) > /tmp/iso/boot/initrd.img

#find | ( set -x; cpio -o -H newc | lz4 -c -l -9 -f ) > /tmp/iso/boot/initrd.img

cd -


# Make the ISO
# Note: only "-isohybrid-mbr /..." is specific to xorriso.
# It builds an image that can be used as an ISO *and* a disk image.
xorriso  \
    -publisher "hernad" \
    -as mkisofs \
    -l -J -R -V "$NAME-v$(cat $ROOTFS/etc/sysconfig/greenbox)" \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat \
    -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
    -o /greenbox.iso /tmp/iso
