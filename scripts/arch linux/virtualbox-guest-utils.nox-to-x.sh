#!/usr/bin/env sh

pacman --noconfirm \
	--remove --nosave --recursive --unneeded \
	virtualbox-guest-utils-nox

pacman --noconfirm \
	--sync --needed --noprogressbar --quiet --refresh \
	virtualbox-guest-utils
