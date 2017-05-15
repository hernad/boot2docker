#!/bin/bash

DOWNLOAD_URL=http://download.bring.out.ba

GREENBOX_VERSION=${1:-4.6.3}

GREENBOX_ISO=greenbox-${GREENBOX_VERSION}.iso
VBOX_NAME=greenbox-test


VBoxManage controlvm greenbox-test poweroff

if [ -f $(pwd)/greenbox-test.vdi ]
then
  VBoxManage closemedium $(pwd)/greenbox-test.vdi --delete 
fi

VBoxManage createmedium disk --filename greenbox-test.vdi \
    --size 20000 \
    --format VDI \
    --variant Standard


if [ ! -f $GREENBOX_ISO ] ; then
   curl -LO $DOWNLOAD_URL/$GREENBOX_ISO
fi

if ! VBoxManage list vms | grep $VBOX_NAME
then

VBoxManage createvm  \
   --basefolder $(pwd) \
   --name $VBOX_NAME \
   --register

fi

#"--natdnshostresolver1", hostDNSResolver,
#"--natdnsproxy1", dnsProxy,

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


VBoxManage storageattach $VBOX_NAME \
		--storagectl SATA \
		--port 0 \
		--device 0 \
		--type dvddrive \
		--medium  $(pwd)/$GREENBOX_ISO


VBoxManage storageattach $VBOX_NAME \
		--storagectl SATA \
		--port 1 \
		--device 0 \
		--type hdd \
		--medium $(pwd)/greenbox-test.vdi
