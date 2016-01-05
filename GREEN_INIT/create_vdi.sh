

#vagrant scp default:/vagrant/GREEN_INIT.vmdk .

rm GREEN_INIT.vdi

VBoxManage clonehd GREEN_INIT.vmdk  GREEN_INIT.vdi
