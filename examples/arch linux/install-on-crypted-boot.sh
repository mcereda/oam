## in live

$ loadkeys it
$ timedatectl set-ntp true

$ cgdisk /dev/sda
# sda1 (gpt) +1MiB ef02
# sda2 (efi) +512MiB ef00
# sda3 (os) +30GiB 8300
# sda4 (data) -2M 8300
# sda5 (gpt) +1MiB ef02

# cifratura
$ cryptsetup --hash sha512 --key-size 512 --use-random --verbose --verify-passphrase luksFormat /dev/sda3
$ cryptsetup --hash sha512 --key-size 512 --use-random --verbose --verify-passphrase luksFormat /dev/sda4
$ cryptsetup --allow-discards luksOpen /dev/sda3 localsysvg
$ cryptsetup --allow-discards luksOpen /dev/sda4 localdatavg

# lvm
$ pvcreate --verbose /dev/mapper/localsysvg
$ pvcreate --verbose /dev/mapper/localdatavg
$ vgcreate --verbose localsysvg /dev/mapper/localsysvg
$ vgcreate --verbose localdatavg /dev/mapper/localdatavg
$ lvcreate --name system --size 10G --verbose localsysvg
$ lvcreate --name recovery --size 4G --verbose localsysvg
$ lvcreate --name swap --extents 100%FREE --verbose localsysvg
$ lvcreate --name data --extents 100%FREE --verbose localdatavg

# filesystem
$ mkfs.fat -n "EFI SYSTEM PARTITION" -F 32 /dev/sda2
$ mkfs.ext4 -E discard -L "System" /dev/localsysvg/system
$ mkfs.ext4 -E discard -L "Recovery" /dev/localsysvg/recovery
$ mkswap --check --label "Swap" /dev/localsysvg/swap
$ mkfs.btrfs -L "Data" /dev/localdatavg/data
$ swapon /dev/localsysvg/swap
$ mount -o discard /dev/localsysvg/system /mnt
$ mkdir -p /mnt/boot/efi
$ mount /dev/sda2 /mnt/boot/efi
$ mkdir /mnt/data

$ vim /etc/pacman.conf
$ vim /etc/pacman.d/mirrorlist
$ pacstrap -i /mnt base bash-completion git dnsmasq efibootmgr fakeroot grub intel-ucode multilib-devel networkmanager pv sudo vim

$ genfstab -p /mnt | tee -a /mnt/etc/fstab
$ vim /mnt/etc/fstab

# per inserire una password di meno al boot
$ dd bs=512 count=4 if=/dev/urandom of=/crypto_keyfile.bin
$ chmod 000 /mnt/crypto_keyfile.bin
$ chmod 600 /mnt/boot/initramfs-linux*
$ cryptsetup luksAddKey /dev/sda3 /mnt/crypto_keyfile.bin
$ cryptsetup luksAddKey /dev/sda4 /mnt/crypto_keyfile.bin

$ vim /mnt/etc/mkinitcpio.conf
# HOOKS=(... encrypt lvm2 ...)
# FILES=(/crypto_keyfile.bin)

$ vim /mnt/etc/lvm/lvm.conf
# issue_discards = 1

$ vim /mnt/etc/default/grub
# GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda3:localsysvg"
# GRUB_CMDLINE_LINUX_DEFAULT="resume=/dev/mapper/localsysvg-swap quiet"
# GRUB_PRELOAD_MODULES="... lvm"
# GRUB_ENABLE_CRYPTODISK=y
# GRUB_DISABLE_LINUX_UUID=true
# GRUB_DISABLE_RECOVERY=false
# GRUB_GFXMODE=auto
# GRUB_GFXPAYLOAD_LINUX=keep

$ vim /mnt/etc/locale.gen
# en_US.UTF-8 UTF-8
# it_IT.UTF-8 UTF-8

$ echo LANG=it_IT.UTF-8 | tee /mnt/etc/locale.conf
$ echo KEYMAP=it | tee /mnt/etc/vconsole.conf
$ echo faraday | tee /mnt/etc/hostname
$ vim /mnt/etc/hosts [127.0.1.1    faraday.localdomain faraday]
$ arch-chroot /mnt

## in chroot

$ ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
$ hwclock --systohc
$ locale-gen
$ mkinitcpio -p linux

# utenza personale
$ useradd --create-home --groups wheel --user-group user
$ passwd user
$ visudo

# grub
$ grub-install --bootloader-id Archlinux --efi-directory /boot/efi --target x86_64-efi
$ grub-mkconfig -o /boot/grub/grub.cfg
$ exit

## in live
$ umount --recursive /mnt
$ reboot

## come utente
# aur
$ for PKG in {aic94xx,b43,wd719x}-firmware
do
  cd
  git clone https://aur.archlinux.org/${PKG}.git
  cd ${PKG}
  makepkg -si
  cd
done

## da root
$ mkinitcpio -p linux

# gui
$ pacman -S breeze-gtk dolphin-plugins drkonqi firefox kde-gtk-config kgamma5 kinfocenter konsole kscreen ksshaskpass kwrite libnotify libva-intel-driver plasma-desktop plasma-nm plasma-pa plasma-wayland-session plasma5-applets-active-window-control plasma5-applets-redshift-control plasma5-applets-thermal-monitor plasma5-applets-weather-widget powerdevil pulseaudio-alsa sddm-kcm ttf-roboto usb_modeswitch vlc xorg

# login grafico
$ systemctl enable sddm
$ mkdir /etc/sddm.conf.d
$ sddm --example-config | tee /etc/sddm.conf.d/sddm.conf
$ vim /etc/sddm.conf.d/sddm.conf
# Current=breeze  CursorTheme=breeze_cursors  MinimumVT=7

# altro
$ systemctl enable NetworkManager
$ localectl set-keymap it
$ timedatectl set-ntp true
$ reboot


---

#  ________________________________________________________________________
# |                                                                            |
# |                                                     .:: BOOT & PREPARE ::. |
# |____________________________________________________________________________|



# increase font size due to 4k display
setfont latarcyrheb-sun32

# connect to wifi network
wifi-menu

# test connection
ping -c 3 github.com



#  ________________________________________________________________________
# |                                                                            |
# |                                                        .:: FORMAT DISK ::. |
# |____________________________________________________________________________|



# this laptop has an nvme disk, so the disk will most likely be "nvme0n1".
# however, you can verify by issuing the command:
lsblk

# create 2 partitions:
# partition 1:
#   - EFI
#   - size 512 MiB
#   - hex code ef00
# partition 2:
#   - Linux/data
#   - size 100%
#   - hex code 8300
cgdisk /dev/nvme0n1

# format EFI partition
mkfs.vfat -F32 /dev/nvme0n1p1

# create and open encrypted Linux/data partition
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 luks

# create partitions on encrypted disk
# we have 2: root and swap
# for swap we use 16 GiB, as the XPS has 16 GiB of memory
pvcreate /dev/mapper/luks
vgcreate vg0 /dev/mapper/luks
lvcreate --size 16G vg0 --name swap
lvcreate -l +100%FREE vg0 --name root

# format encrypted partition
mkfs.ext4 /dev/mapper/vg0-root
mkswap /dev/mapper/vg0-swap

# mount system
mount /dev/mapper/vg0-root /mnt
swapon /dev/mapper/vg0-swap
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot



#  ________________________________________________________________________
# |                                                                            |
# |                                                .:: INSTALL BASE SYSTEM ::. |
# |____________________________________________________________________________|



# select mirror
# uncomment the mirror closest to you
vim /etc/pacman.d/mirrorlist

# install base packages
# NOTE: as of recently, the base package doesn't include linux anymore!
pacstrap -i /mnt base base-devel linux linux-headers zsh vim git sudo efibootmgr dialog iw wpa_supplicant

# generate fstab
genfstab -pU /mnt >> /mnt/etc/fstab

# verify and adjust /mnt/etc/fstab
# change "relatime" on all non-boot partitions to "noatime" to reduce wear on the SSD
vim /mnt/etc/fstab

# enter the new system
arch-chroot /mnt /bin/bash



#  ________________________________________________________________________
# |                                                                            |
# |                                                   .:: CONFIGURE SYSTEM ::. |
# |____________________________________________________________________________|



# configure locale
# uncomment "en_US.UTF-8"
vim /etc/locale.gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8
echo LC_ALL= >> /etc/locale.conf
locale-gen

# configure timezone
tzselect
ln -s /usr/share/zoneinfo/Europe/Brussels /etc/localtime
hwclock --systohc --utc

# configure font for 4k display
echo 'FONT=latarcyrheb-sun32' >> /etc/vconsole.conf

# configure hostname
# change "<my_hostname>" to one of your choosing
echo '<my_hostname>' > /etc/hostname
echo '127.0.1.1 <my_hostname>.localdomain <my_hostname>' >> /etc/hosts

# configure root password
passwd

# add and configure your user
# change "<my_username>" to one of your choosing
useradd -m -g users -G wheel -s /bin/zsh <my_username>
passwd <my_username>
echo '<my_username> ALL=(ALL) ALL' > /etc/sudoers.d/<my_username>
EDITOR=vim visudo



#  ________________________________________________________________________
# |                                                                            |
# |                                                .:: INSTALL BOOT LOADER ::. |
# |____________________________________________________________________________|



# install Intel's microcode updates
pacman -S intel-ucode

# configure mkinitcpio with modules needed for the initrd image
# add or update the following to or in /etc/mkinitcpio.conf:
#
#   MODULES="i915 ext4 nvme intel_agp"
#   BINARIES=""
#   FILES="/etc/modprobe.d/modprobe.conf"
#   HOOKS="systemd autodetect modconf block keymap sd-encrypt sd-lvm2 filesystems keyboard"
#
vim /etc/mkinitcpio.conf

# regenerate initrd image
mkinitcpio -p linux

# setup systembootd
bootctl --path=/boot install

# get your LUKS UUID
cryptsetup luksUUID /dev/nvme0n1p2

# create bootloader entry with powersaving
# replace <UUID> with the output of the previous command
# add the following lines to /boot/loader/entries/arch.conf:
#
#   title Arch Linux
#   linux /vmlinuz-linux
#   initrd /intel-ucode.img
#   initrd /initramfs-linux.img
#   options luks.uuid=<UUID> luks.name=<UUID>=luks root=/dev/mapper/vg0-root resume=/dev/mapper/vg0-swap rw nvme_core.default_ps_max_latency_us=170000
#
vim /boot/loader/entries/arch.conf

# create loader.conf file, and add the following content:
#
#   default arch
#   timeout 0
#   editor  0
#
vim /boot/loader/loader.conf

# enable Intel GPU and powersaving options needed for tear free operation, and battery life
# create the i915 modprobe file (Intel graphics powersaving options), and add the following content:
#
#   options i915 enable_rc6=1 enable_fbc=1 semaphores=1 modeset=1 enable_guc_loading=1 enable_guc_submission=1 enable_huc=1 disable_power_well=0 enable_psr=1
#
vim /etc/modprobe.d/i915.conf

# create the X11 Intel config file, and add the following content:
#
#   Section "Device"
#      Identifier  "Intel Graphics"
#      Driver      "intel"
#      Option      "AccelMethod"
#   EndSection
#
vim /etc/X11/xorg.conf.d/20-intel.conf

# update bootloader
bootctl update



#  ________________________________________________________________________
# |                                                                            |
# |                                .:: INSTALL DESKTOP ENVIRONMENT & TOOLS ::. |
# |____________________________________________________________________________|



# install GNOME & GDM & networking tools
pacman -S gnome gdm network-manager-applet networkmanager gnome-clocks gnome-software gnome-boxes gnome-calendar gnome-maps gnome-bluetooth gnome-user-share gnome-characters gnome-color-manager gnome-documents gnome-logs gnome-music gnome-photos gnome-todo seahorse file-roller

# install touchpad & graphics
pacman -S xf86-input-libinput xf86-video-intel mesa-libgl vulkan-intel libva-intel-driver

# start GNOME on boot
systemctl enable NetworkManager.service
systemctl enable gdm.service

# reboot and start using Arch
exit
umount -R /mnt
swapoff -a
reboot



#  ________________________________________________________________________
# |                                                                            |
# |                                             .:: POST INSTALL UTILITIES ::. |
# |____________________________________________________________________________|



# update system
sudo pacman -Syyu

# check if NVME (Toshiba) SSD has powersaving mode enabled
sudo nvme get-feature -f 0x0c -H /dev/nvme0

# ensure Intel Video drivers are used
sudo lspci -s 00:02 -vk

# ensure the following options are set in i915 config:
#
#   options i915 modeset=1 enable_rc6=1 enable_fbc=1
#
sudo vim /etc/modprobe.d/i915.conf

# install utilities:
#   - basic tools such as bluetooth
#   - printing tools
#   - dmidecode: for dumping DMI/SMBIOS in human readable format
sudo pacman -Syu terminator gnome-tweak-tool systemd-swap util-linux dosfstools lshw \
                 bluez bluez-utils bluez-libs bluez-firmware \
                 cups cups-pdf gtk3-print-backends \
                 dmidecode \
                 xdotool wmctrl ffmpeg pulseaudio-alsa pulseaudio-bluetooth alsa-utils

# enable and start Bluetooth
sudo modprobe btusb
sudo systemctl start bluetooth.service
sudo systemctl enable bluetooth.service

# auto enable Bluetooth
# change AutoEnable to true in the [Policy] section:
#
#SET AutoEnable=True
#
sudo vim /etc/bluetooth/main.conf

# enable and start printing service
sudo systemctl start org.cups.cupsd.service
sudo systemctl enable org.cups.cupsd.service

# enable SWAP service
sudo systemctl enable systemd-swap.service

# enable SSD TRIM
sudo systemctl enable fstrim.timer

# install yay
cd <YOUR_DIRECTORY>
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# install fonts
sudo pacman -S adobe-source-code-pro-fonts adobe-source-han-sans-cn-fonts adobe-source-han-sans-jp-fonts adobe-source-han-sans-kr-fonts adobe-source-han-sans-otc-fonts adobe-source-han-sans-tw-fonts adobe-source-sans-pro-fonts noto-fonts-emoji otf-ipafont ttf-dejavu ttf-hanazono ttf-inconsolata ttf-liberation ttf-roboto ttf-ubuntu-font-family
yay -S ttf-google-fonts-git ttf-ms-fonts

# install some more QOL utilities
sudo pacman -S neofetch etcher steam vlc firefox qt4 thunderbird libreoffice ufw gnome-clocks gnome-software gnome-boxes gnome-calendar gnome-maps gnome-bluetooth gnome-user-share gnome-characters gnome-color-manager gnome-documents gnome-logs gnome-music gnome-photos gnome-todo seahorse file-roller
yay -S etcher-bin brave-bin spotify skypeforlinux-stable-bin timeshift

# hide unwanted desktop file icons
# create a script with the following content:
#
#   #!/bin/sh
#
#   APPLICATION_PATH="/usr/share/applications"
#   USER_APPLICATION_PATH="${HOME}/.local/share/applications"
#
#   for FILE in cat $1; do
#       if [ -e "${APPLICATION_PATH}/${FILE}" ]; then
#           echo "Creating file ${USER_APPLICATION_PATH}/${FILE}"
#           echo "NoDisplay=true" > "${USER_APPLICATION_PATH}/${FILE}"
#       elif [ ! -e "${APPLICATION_PATH}/${FILE}" ] && [ -e "${USER_APPLICATION_PATH}/${FILE}" ]; then
#           echo "Deleting unnecessary file ${USER_APPLICATION_PATH}/${FILE}"
#           rm "${USER_APPLICATION_PATH}/${FILE}"
#       fi
#   done
#
vim ~/hide_desktop_icons.sh

# create a list if icons you want to hide with the following content:
#
#   assistant-qt4.desktop
#   avahi-discover.desktop
#   bssh.desktop
#   bvnc.desktop
#   CMake.desktop
#   designer-qt4.desktop
#   ipython-qtconsole.desktop
#   jconsole.desktop
#   linguist-qt4.desktop
#   policytool.desktop
#   qdbusviewer-qt4.desktop
#   qtconfig-qt4.desktop
#   qv4l2.desktop
#   gda-control-center-5.0.desktop
#   gda-browser-5.0.desktop
#   nvidia-settings.desktop
#   hplip.desktop
#   ipython.desktop
#   zenmap.desktop
#   zenmap-root.desktop
#   designer.desktop
#   qdbusviewer.desktop
#   assistant.desktop
#   linguist.desktop
#
vim ~/hide_desktop_icons_list.txt

# execute script
chmod +x hide-icon.sh
./hide-icon.sh list_of_desktop_file_names.txt



#  ________________________________________________________________________
# |                                                                            |
# |                                                         .:: REFERENCES ::. |
# |____________________________________________________________________________|



https://wiki.archlinux.org/index.php/Dell_XPS_13_2-in-1_(7390)
https://gist.github.com/huntrar/e42aee630bee3295b2c671d098c81268
https://gist.github.com/chrisleekr/a23e93edc3b0795d8d95f9c70d93eedd
https://gist.github.com/ymatsiuk/1181b514a9c1979088bd2423a24928cf
