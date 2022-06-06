#!/usr/bin/env sh

# sources:
# - https://openzfs.github.io/openzfs-docs/Getting%20Started/Fedora/index.html

# needs to be installed before zsf
sudo dnf install -y kernel-devel

# the repo's package is not maintained
sudo rpm -e --nodeps zfs-fuse

sudo dnf install -y https://zfsonlinux.org/fedora/zfs-release$(rpm -E %dist).noarch.rpm
sudo dnf install -y zfs
echo zfs | sudo tee /etc/modules-load.d/zfs.conf
sudo modprobe zfs
