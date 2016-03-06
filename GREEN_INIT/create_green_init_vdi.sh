#!/bin/bash

if [[ "$1" == "--create-tgz" ]] ; then
   tar -cvf green_init.tar.gz  -C data  . 
fi

vagrant up # create default vdi

if [ ! -f GREEN_INIT.vmdk ] ; then
   vagrant provision  # vmdk not created in previous step
fi

if [ -f GREEN_INIT.vmdk ] ; then
   vagrant scp default:/vagrant/GREEN_INIT.vmdk .
else
   echo "GREEN_INIT.vmdk not created!"
   exit 1
fi

rm GREEN_INIT.vdi
VBoxManage clonehd GREEN_INIT.vmdk  GREEN_INIT.vdi

VBoxManage closemedium GREEN_INIT.vdi
rm GREEN_INIT.vmdk

