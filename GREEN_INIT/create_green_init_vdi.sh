#!/bin/bash

vagrant up # create default vdi


if [[ "$1" == "--create-tgz" ]] ; then
   tar -cvf green_init.tar.gz  -C data  . 
   vagrant rsync
fi


vagrant ssh -c "ls -l /vagrant/green_init.tar.gz"

if [ ! -f GREEN_INIT.vmdk ] ; then
   vagrant reload --provision   # vmdk not created in previous step
fi


vagrant scp default:/vagrant/GREEN_INIT.vmdk .

rm GREEN_INIT.vdi
VBoxManage clonehd GREEN_INIT.vmdk  GREEN_INIT.vdi

VBoxManage closemedium GREEN_INIT.vdi
rm GREEN_INIT.vmdk

