#!/bin/sh

DISK=sda
POOL=green

. /etc/green_common

extract_userdata_tar() {

# docker-machine creates this volume
LABEL=boot2docker-data
MAGIC="boot2docker, please format-me"

# If there is a partition with `boot2docker-data` as its label, use it and be
# very happy. Thus, you can come along if you feel like a room without a roof.
BOOT2DOCKER_DATA=`blkid -o device -l -t LABEL=$LABEL`
echo $BOOT2DOCKER_DATA

if [ ! -n "$BOOT2DOCKER_DATA" ]; then
    echo "Is the disk unpartitioned?, test for the 'boot2docker format-me' string"

    # Is the disk unpartitioned?, test for the 'boot2docker format-me' string
    UNPARTITIONED_HD=`fdisk -l | grep "doesn't contain a valid partition table" | head -n 1 | sed 's/Disk \(.*\) doesn.*/\1/'`

    if [ -n "$UNPARTITIONED_HD" ]; then
        # Test for our magic string (it means that the disk was made by ./boot2docker init)
        HEADER=`dd if=$UNPARTITIONED_HD bs=1 count=${#MAGIC} 2>/dev/null`

        if [ "$HEADER" = "$MAGIC" ]; then
            # save the preload userdata.tar file
            dd if=$UNPARTITIONED_HD of=/userdata.tar bs=1 count=4096 2>/dev/null
        fi
    fi
fi

}



fdisk_exist () {
fdisk -l /dev/${DISK} | grep -q "/dev/$1"
}

if ( ! is_vbox )
then
   log_msg "automatsko kreiranje zpool-a: mora biti vbox"
   exit 1
fi

echo "${GREEN}vbox create pool.sh start${NORMAL}"
if ( zpool list | grep -q $POOL )
then
  echo "zpool green already exists"
  exit 0
fi

extract_userdata_tar

fdisk -l /dev/$DISK >> $LOG_FILE

if ( ! fdisk_exist ${DISK}1 )
then
  log_msg "vbox zpool fdisk create $DISK partition 1"
  #n p 1 1 <enter> w
  #(echo n; echo p; echo 1; echo 1; echo ; echo w) | fdisk /dev/${DISK}
  log_msg "zpool create $POOL na /dev/${DISK}1"
  zpool create -f $POOL /dev/${DISK}
  zpool list >> $LOG_FILE
else
  log_msg "${DISK} partition 1 already exists"
  exit 1
fi
