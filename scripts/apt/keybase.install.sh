#!/usr/bin/env sh
# https://keybase.io/docs/the_app/install_linux

export \
	DEBIAN_FRONTEND='noninteractive' \
	LC_ALL='C'

curl https://prerelease.keybase.io/keybase_amd64.deb \
	--output /tmp/keybase_amd64.deb \
	--silent

sudo apt update && sudo apt install --assume-yes /tmp/keybase_amd64.deb
rm keybase_amd64.deb
