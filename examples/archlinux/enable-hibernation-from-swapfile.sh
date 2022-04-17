#!/bin/sh

# enable hibernation from a swapfile on btrfs

# source:
#  - https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate

sudo mkdir /swap

# disable copy-on-write and compression on the directory
sudo chattr -R +C /swap
sudo btrfs property set /swap compression none

# create the swapfile
sudo fallocate -l 32GiB /swap/swapfile
sudo chmod -R 600 /swap
sudo mkswap --label swap /swap/swapfile
sudo swapon /swap/swapfile

# configure swappiness
sudo nano /etc/sysctl.d/swappiness
sudo sysctl --load=/etc/sysctl.d/swappiness

# identify the swap device
# value is to be used for the resume=UUID= kernel parameter
sudo findmnt -no UUID -T /swap/swapfile

# identify the file offset
# value is to be used for the resume_offset= kernel parameter
curl --location --output /tmp/btrfs_map_physical.c https://raw.githubusercontent.com/osandov/osandov-linux/master/scripts/btrfs_map_physical.c
gcc -O2 -o /tmp/btrfs_map_physical /tmp/btrfs_map_physical.c
chmod a+x /tmp/btrfs_map_physical
physical_offset=$(sudo /tmp/btrfs_map_physical /swap/swapfile | awk '$1==0 {print $NF}')   # last column of the line starting with 0
resume_offset=$(( ${physical_offset} / $(getconf PAGESIZE) ))

# configure the bootloader
# GRUB_CMDLINE_LINUX_DEFAULT="quiet cryptdevice=UUID=... resume=UUID=bac7930a-924d-4e9d-83eb-ad6ce5a8100a resume_offset=1865170"
sudo nano /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# configure the mkinitcpio
# not needed if using the systemd hook
# add resume after filesystems: HOOKS=(base ... filesystems resume fsck)
sudo nano /etc/mkinitcpio.conf
mkinitcpio -p linux

# reboot

# check with `systemctl hibernate`
