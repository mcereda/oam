#!/usr/bin/env sh

# sources:
# - https://software.opensuse.org/download/package?package=keybase-client&project=openSUSE%3AFactory

# sudo zypper addrepo --refresh https://download.opensuse.org/repositories/openSUSE:Factory/standard/openSUSE:Factory.repo
sudo zypper --non-interactive install git-lfs
sudo zypper --non-interactive install keybase-client

keybase login mek
