

# btrfs postgresql

https://www.slideshare.net/fuzzycz/postgresql-on-ext4-xfs-btrfs-and-zfs

# btrfs

https://zyisrad.com/filesystem-resilience-with-dm-crypt-btrfs-and-overlayfs


Use raid10 for both data and metadata

      mkfs.btrfs -m raid10 -d raid10 /dev/sdb /dev/sdc /dev/sdd /dev/sde



## btrfs device add /dev/sdc /mnt

At this point we have a filesystem with two devices, but all of the metadata and data are still # stored on the original device(s). The filesystem must be balanced to spread the files across all of the devices.

       btrfs filesystem balance /mnt



A non-raid filesystem is converted to raid by adding a device and running a balance filter that will change the chunk allocation profile.
For example, to convert an existing single device system (/dev/sdb1) into a 2 device raid1 (to protect against a single disk failure):

     mount /dev/sdb1 /mnt
     btrfs device add /dev/sdc1 /mnt
     btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt


## btrfs raid migrate

https://blog.christophersmart.com/2016/08/26/live-migrating-btrfs-from-raid-56-to-raid-10/



## btrfs maintenance

https://wiki.debian.org/Btrfs

ZFS addresses the performance problems of fragmentation using an intelligent Adaptive Replacement Cache (ARC); the ARC requires massive amounts of RAM. Btrfs took a different approach, and benefits from—some would say requires—periodic defragmentation. In the future, maintenance of btrfs volumes on Debian systems will be automated using btrfsmaintenance. For now use:

     sudo ionice -c idle btrfs filesystem defragment -t 32M -r $PATH

This command must be run as root, and it is recommended to ionice it to reduce the load on the system. To further reduce the IO load, flush data after defragmenting each file using:

     sudo ionice -c idle btrfs filesystem defragment -f -t 32M -r $PATH

Target extent size is a little known, but for practical purposes absolutely essential argument. By default btrfs fi defrag only defrags files of less than 256KiB, because does not touch extents bigger than $SIZE, where $SIZE is by default 256KiB! While argument "-t 1G" would seem to be better than "-t 32M", because most volumes will have 1GiB chunk size, in practise this is not the case. Additionally, if you have a lot of snapshots or reflinked files, please use "-f" to flush data for each file before going to the next file. As of btrfs-progs-4.6.1, "-t 32M" is still necessary, but "-t 32M" is the default after btrfs-progs-4.7. Please consult the following linux-btrfs thread for more information.


# btrfs zram

https://seravo.fi/2016/perfect-btrfs-setup-for-a-server

https://wiki.gentoo.org/wiki/Zram


http://blog.fabio.mancinelli.me/data/arch_linux_on_btrfs_installation.txt


# coreos btrfs - ext4

https://lwn.net/Articles/627232/


# noatime

https://btrfs.wiki.kernel.org/index.php/Mount_options

https://www.postgresql.org/message-id/3F5DCB35.3090809@potentialtech.com
