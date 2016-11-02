#!/bin/bash


( vagrant status | grep -q "not created" ) || ( echo "destroying vm" && vagrant destroy --force )


vagrant destroy --force 

for ext in "vmdk img vdi" ; do
  [ -f GREEN_INIT.$ext ]  || rm GREEN_INIT.$ext
done


if [[ "$1" == "--create-tgz" ]] ; then
   tar -cvf green_init.tar.gz  -C data  . 
fi


vagrant up # create default vdi

vagrant ssh -c "ls -l /vagrant/green_init.tar.gz"

#if [ ! -f GREEN_INIT.vmdk ] ; then
#   vagrant reload --provision   # vmdk not created in previous step
#fi

vagrant scp default:/vagrant/GREEN_INIT.vmdk .

rm GREEN_INIT.vdi
VBoxManage clonehd GREEN_INIT.vmdk  GREEN_INIT.vdi

VBoxManage closemedium GREEN_INIT.vdi
rm GREEN_INIT.vmdk


( vagrant status | grep -q running ) && echo destroying && vagrant destroy --force

