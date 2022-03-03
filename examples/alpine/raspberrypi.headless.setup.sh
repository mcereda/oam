#!/usr/bin/env sh

# https://wiki.alpinelinux.org/wiki/Raspberry_Pi_-_Headless_Installation

setup-ntp -c chrony
setup-keymap
setup-hostname raspberrypi
setup-timezone -z Europe/Amsterdam
setup-lbu -q
setup-apkcache
setup-apkrepos

apk add rng-tools
rc-update add rngd boot
# rc-update add wpa_supplicant boot
rc-update add urandom boot

mount -o remount,rw /media/mmcblk0p1
rm /media/mmcblk0p1/headless.apkovl.tar.gz
rm /media/mmcblk0p1/wifi.txt

rc-update del local default
rm /etc/local.d/headless.start

passwd

adduser $USER
apk add sudo
echo "${USER} ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/${USER}

lbu commit -d
reboot
