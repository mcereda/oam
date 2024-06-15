#!/usr/bin/env sh

sudo pacman --noconfirm --sync --refresh

sudo pacman --sync --refresh 'clinfo' 'opencl-mesa'
sudo pacman --noconfirm --sync --needed --quiet 'virtualbox-guest-utils'

sudo pacman --noconfirm --sync --clean --clean
