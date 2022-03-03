#!/bin/sh

# sources:
# - https://en.opensuse.org/Additional_package_repositories

sudo zypper --non-interactive install ansible dolphin-plugins

# sudo zypper addrepo --check --refresh --priority 90 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_$releasever/' packman
sudo zypper addrepo --check --refresh --priority 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman

sudo zypper addrepo --check --refresh --priority 90 https://download.opensuse.org/repositories/mozilla/openSUSE_Tumbleweed/ mozilla

./chromium.install.sh
./keybase.install.sh
