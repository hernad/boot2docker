#!/bin/bash

# Thank you githib.com/RackHD/RackHD

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
source $SCRIPT_DIR/deploy.cfg


function usage {
  printf "\nusage: vbox_deploy [-h]\n"
  printf "\t-h display usage\n\n"
  printf "\t customize deployment variables by editing:\n"
  printf "\t\t deploy.cfg\n\n"
  exit
}


function vbox_create {

vmName=$1
vmDiskSize=$2

echo "deploying machine: $vmName"

( VBoxManage showvminfo $vmName > /dev/null ) && echo "$vmName already exists" && return


VBoxManage createvm --name $vmName --register
VBoxManage modifyvm $vmName --ostype Linux_64  --memory $vmMemory

VBoxManage modifyvm $vmName --nic1 nat   # eth0
#VBoxManage modifyvm $vmName --nictype1 virtio

if [ $vmNet2Type == "hostonly" ] ; then
  VBoxManage modifyvm $vmName --nic2 hostonly  \
    --hostonlyadapter2 $vmNet2Name  --nicpromisc1 allow-all # eth1
else
  VBoxManage modifyvm $vmName --nic2 intnet --intnet2 $vmNet2Name --nicpromisc1 allow-all # eth1, greennet
fi

#VBoxManage modifyvm $vmName --nictype2 virtio --macaddress1 auto

VBoxManage createhd --filename $vmName --size $vmDiskSize

VBoxManage storagectl $vmName --name "IDE Controller" --add ide
VBoxManage storageattach $vmName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "greenbox.iso"  # boot CD iso

VBoxManage storagectl $vmName --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach $vmName --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $vmName.vdi # hdd

if [ "$green_init_hdd" == "1" ] ; then
  VBoxManage clonehd ../GREEN_INIT/GREEN_INIT.vdi  ${vmName}_GREEN_INIT.vdi
  VBoxManage storageattach $vmName --storagectl "SATA Controller" --port 1 --device 0 --type hdd --medium ${vmName}_GREEN_INIT.vdi # GREEN_INIT hdd
else
  echo "no GREN_INIT vdi"
fi
 
}

while getopts ":h" opt; do
  case $opt in
    h)
      usage
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
  esac
done


VBoxManage dhcpserver add --netname $vmNet2Name --ip 10.0.200.1 --lowerip 10.0.200.10 --upperip 10.0.200.200 --netmask 255.255.255.0 --enable


if [ $machine_count ]
  then
    for (( i=1; i <= $machine_count; i++ ))
      do
        vmName="greenbox-$i"
        vbox_create $vmName $vmDiskSize
      done
fi

echo end
#vagrant ssh dev -c "sudo nf start"
