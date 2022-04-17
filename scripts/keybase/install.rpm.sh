#!/usr/bin/env sh
# https://keybase.io/docs/the_app/install_linux

: "${PKG_MGR:=$(command which dnf yum zypper 2>/dev/null | head -n 1)}"
sudo $PKG_MGR install --assumeyes https://prerelease.keybase.io/keybase_amd64.rpm

run_keybase
