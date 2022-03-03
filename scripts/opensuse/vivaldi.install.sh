#!/usr/bin/env sh

# sources:
# - https://forums.opensuse.org/showthread.php/538576-Installing-Vivaldi-browser-(based-on-a-Chromium)-into-the-openSUSE

sudo zypper addrepo --refresh https://repo.vivaldi.com/archive/vivaldi-suse.repo
# sudo zypper repos --sort-by-priority
sudo zypper --non-interactive install vivaldi-stable
