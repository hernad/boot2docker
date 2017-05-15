#!/bin/bash

DOWNLOAD_URL=http://download.bring.out.ba

GREENBOX_VERSION=${1:-4.6.3}

GREENBOX_ISO=greenbox-${GREENBOX_VERSION}.iso
VBOX_NAME=greenbox-test


echo " $VBOX_NAME 1) poweroff"

VBoxManage controlvm $VBOX_NAME poweroff


if [ ! -f $GREENBOX_ISO ] ; then
   curl -LO $DOWNLOAD_URL/$GREENBOX_ISO
fi

if ! VBoxManage list vms | grep $VBOX_NAME
then

   echo " $VBOX_NAME 2) createvm"
   VBoxManage createvm  \
      --basefolder $(pwd) \
      --name $VBOX_NAME \
      --register


   VBoxManage modifyvm greenbox-test \
      --firmware bios \
      --bioslogofadein off \
      --bioslogofadeout off \
      --bioslogodisplaytime 0 \
      --biosbootmenu disabled \
      --ostype Linux26_64 \
      --cpus  1 \
      --memory   1024 \
      --acpi on \
      --ioapic on \
      --rtcuseutc on \
      --cpuhotplug off \
      --pae on \
      --hpet on \
      --hwvirtex on \
      --nestedpaging on \
      --largepages  on \
      --vtxvpid  on \
      --accelerate3d  off \
      --boot1 dvd


  VBoxManage modifyvm $VBOX_NAME \
	--nic1 nat \
        --nictype1 virtio \
        --cableconnected1 on 

  VBoxManage storagectl $VBOX_NAME \
	--name  SATA \
	--add sata \
	--hostiocache on \


fi

#"--natdnshostresolver1", hostDNSResolver,
#"--natdnsproxy1", dnsProxy,

echo " $VBOX_NAME 3) storageattach iso"
VBoxManage storageattach $VBOX_NAME \
		--storagectl SATA \
		--port 0 \
		--device 0 \
		--type dvddrive \
		--medium  $(pwd)/$GREENBOX_ISO


echo " $VBOX_NAME 4) storage detach $VBOX_NAME.vdi"
VBoxManage storageattach $VBOX_NAME \
		--storagectl SATA \
		--port 1 \
		--device 0 \
		--type hdd \
		--medium none


if [ -f $(pwd)/${VBOX_NAME}.vdi ]
then
  echo " $VBOX_NAME 5) close medium $VBOX_NAME.vdi"
  VBoxManage closemedium $(pwd)/${VBOX_NAME}.vdi --delete 
fi

echo " $VBOX_NAME 6) create medium disk $VBOX_NAME.vdi"
VBoxManage createmedium disk --filename ${VBOX_NAME}.vdi \
    --size 20000 \
    --format VDI \
    --variant Standard

echo " $VBOX_NAME 7) storage attach $VBOX_NAME.vdi"
VBoxManage storageattach $VBOX_NAME \
		--storagectl SATA \
		--port 1 \
		--device 0 \
		--type hdd \
		--medium $(pwd)/${VBOX_NAME}.vdi

VBoxManage startvm ${VBOX_NAME}
