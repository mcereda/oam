#!/bin/sh

# sources:
# - https://en.opensuse.org/OpenZFS

sudo zypper addrepo --refresh https://download.opensuse.org/repositories/filesystems/openSUSE_Tumbleweed/filesystems.repo
sudo zypper install --no-confirm zfs
