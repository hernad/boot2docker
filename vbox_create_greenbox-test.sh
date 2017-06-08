#!/bin/bash

DOWNLOAD_URL=http://download.bring.out.ba

GREENBOX_VERSION=${1:-4.6.3}
if [ "$2" == "--no-delete-vdi" ] ; then
  echo "no delete vdi"
  NO_DELETE_VDI=1
fi

BRIDGE_ADAPTER=${BRIDGE_ADAPTER:-en0}

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

  VBoxManage modifyvm $VBOX_NAME \
	--nic2 bridged \
        --nictype2 virtio \
        --bridgeadapter2 $BRIDGE_ADAPTER \
        --nicpromisc2 allow-vm \
        --cableconnected2 on

  #VBoxManage modifyvm foo1 --nic2 bridged --nictype2 82540EM --bridgeadapter1 'eth0' 

 
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


[ -n "$NO_DELETE_VDI" ] && echo "leaving existing VDI" && VBoxManage startvm ${VBOX_NAME} && exit 0

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

VBoxManage modifyvm ${VBOX_NAME} --natpf1 "ssh,tcp,,2222,,22"
VBoxManage modifyvm ${VBOX_NAME} --natpf1 "http,tcp,,8080,,80"
VBoxManage modifyvm ${VBOX_NAME} --natpf1 "https,tcp,,4430,,443"

VBoxManage startvm ${VBOX_NAME}
