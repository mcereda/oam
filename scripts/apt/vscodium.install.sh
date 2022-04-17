#!/usr/bin/env sh

export \
	DEBIAN_FRONTEND='noninteractive' \
	LC_ALL='C'

wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
| gpg --dearmor \
| sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

echo 'deb [signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main' \
| sudo tee /etc/apt/sources.list.d/vscodium.list

sudo apt update && sudo apt --assume-yes install codium
