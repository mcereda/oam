#!/usr/bin/env sh

# sources
# - https://wiki.gentoo.org/wiki/Handbook:AMD64
# - https://wiki.gentoo.org/wiki/Localization/Guide

# start with gentoo live, with UEFI

# /etc/init.d/sshd start
# passwd $complicated_password

sgdisk --zap-all /dev/sda
sgdisk --clear /dev/sda

sgdisk --new 1:2048:+128M /dev/sda
sgdisk --typecode 1:ef00 /dev/sda
sgdisk --change-name 1:EFI /dev/sda
mkfs.vfat -F 32 -n EFI /dev/sda1

sgdisk --new 2:+0M: /dev/sda
sgdisk --change-name 2:ROOT /dev/sda
mkfs.ext4 -F -L System /dev/sda2

mkdir -p /mnt/gentoo
mount /dev/sda2 /mnt/gentoo
mkdir -p /mnt/gentoo/boot
chattr +i /mnt/gentoo/boot
mount /dev/sda1 /mnt/gentoo/boot

hwclock --systohc
ntpd -q -g

cd /mnt/gentoo

wget https://ftp.snt.utwente.nl/pub/os/linux/gentoo/releases/amd64/autobuilds/current-stage3-amd64-hardened/stage3-amd64-hardened-20210623T214504Z.tar.xz
tar -xpf stage3-amd64-*.tar.xz
rm -f stage3-amd64-*.tar.xz

wget https://ftp.snt.utwente.nl/pub/os/linux/gentoo/snapshots/portage-latest.tar.xz
tar -xf portage-latest.tar.xz -C /mnt/gentoo/usr
rm -f portage-latest.tar.xz

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

cp /etc/resolv.conf /mnt/gentoo/etc
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
ping -c 3 google.com

fallocate -l 1G /swapfile   # or sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

mkdir -p /etc/portage/package.{accept_keywords,license,use}

JOBS="$(nproc)"
LOAD_AVERAGE="$(python -c "print($(nproc)*0.9)")"
cat >> /etc/portage/make.conf <<EOF

AUTOCLEAN="yes"
FEATURES="candy compress-build-logs parallel-install"
GRUB_PLATFORMS="efi-64"
L10N="en-US"
LINGUAS="en_US"
USE="hardened"

# use all the cpu threads but keep load average to 90%
# see https://wiki.gentoo.org/wiki/EMERGE_DEFAULT_OPTS
EMERGE_DEFAULT_OPTS="--jobs $JOBS --load-average $LOAD_AVERAGE"
MAKEOPTS="--jobs $JOBS --load-average $LOAD_AVERAGE"
EOF

emerge --sync

echo "Europe/Amsterdam" > /etc/timezone
emerge --config sys-libs/timezone-data

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set "en_US.utf8"
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

cat > /etc/fstab <<EOF
# The root filesystem should have a pass number of either 0 or 1.
# All other filesystems should have a pass number of 0 or greater than 1.
#
# NOTE: If your BOOT partition is ReiserFS, add the notail option to opts.
#
# See the manpage fstab(5) for more information.
#
# <fs>        <mountpoint>  <type>  <opts>           <dump/pass>

LABEL=EFI     /boot         vfat    noauto,noatime   1 2
LABEL=System  /             ext4    discard,noatime  0 1

/swapfile     swap          swap    defaults         0 0
#tmpfs        /run          tmpfs   rw,nodev,nosuid  0 0
EOF

echo 'hostname="gentoo"' > /etc/conf.d/hostname

echo "sys-kernel/linux-firmware  linux-fw-redistributable no-source-code" > /etc/portage/package.license/kernel
emerge \
  --quiet --verbose \
  sys-kernel/gentoo-sources sys-kernel/genkernel
eselect kernel set 1
genkernel all

emerge \
  --quiet --verbose \
  --noreplace \
  net-misc/netifrc
echo 'config_enp0s3="dhcp"' > /etc/conf.d/net
sed -i.bak \
  -e 's/^127.0.0.1.*/127.0.0.1\tlocalhost gentoo/' \
  -e 's/^::1.*/::1\t\tlocalhost gentoo/' \
  /etc/hosts
cd /etc/init.d
ln -s net.lo net.enp0s3
rc-update add net.enp0s3 default
cd -

sed -i.bak 's/^enforce=everyone$/enforce=none/' /etc/security/passwdqc.conf
emerge \
  --quiet --verbose \
  app-admin/sudo
echo '%wheel ALL=(ALL) ALL' | tee /etc/sudoers.d/wheel
useradd -m -G users,wheel,audio -s /bin/bash mek
passwd mek
passwd -l root

emerge \
  --quiet --verbose \
  app-admin/sysklogd
rc-update add sysklogd default

emerge \
  --quiet --verbose \
  sys-process/cronie
rc-update add cronie default

emerge \
  --quiet --verbose \
  net-misc/dhcpcd
rc-update add dhcpcd default

rc-update add sshd default

echo 'sys-process/bpytop ~amd64' | tee /etc/portage/package.accept_keywords/bpytop
emerge \
  --quiet --verbose \
  bpytop \
  nfs-utils \
  samba \
  tmux

emerge \
  --quiet --verbose \
  sys-boot/grub:2
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg

exit

cd
umount -lR /mnt/gentoo
reboot
