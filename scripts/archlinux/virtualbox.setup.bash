#!/usr/bin/env bash

packages="virtualbox virtualbox-host-modules-arch"

sudo pacman -S ${packages}
sudo gpasswd -a $USER vboxusers
#sudo reboot

vbox_version="$(vboxmanage --version)"
version=${vbox_version%r*}
file="Oracle_VM_VirtualBox_Extension_Pack-${version}.vbox-extpack"

curl -o /tmp/${file} -s https://download.virtualbox.org/virtualbox/${version}/${file}
sudo VBoxManage extpack install /tmp/${file} --accept-license=56be48f923303c8cababb0bb4c478284b688ed23f16d775d729b89a2e8e5f9eb --replace
