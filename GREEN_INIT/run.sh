#!/bin/bash

cd data
tar cvfz ../green_init.tar.gz .
cd ..

vagrant up
vagrant rsync
vagrant provision
./create_vdi.sh

vagrant halt
