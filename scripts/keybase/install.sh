#!/usr/bin/env sh
# https://keybase.io/docs/the_app/install_linux

curl https://prerelease.keybase.io/keybase_amd64.deb \
	--output /tmp/keybase_amd64.deb \
	--silent
LC_ALL='C' sudo apt install --assume-yes /tmp/keybase_amd64.deb
rm keybase_amd64.deb

run_keybase

# sudo dnf install --assumeyes https://prerelease.keybase.io/keybase_amd64.rpm
# sudo yum install --assumeyes https://prerelease.keybase.io/keybase_amd64.rpm
