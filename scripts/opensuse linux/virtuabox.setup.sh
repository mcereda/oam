#!/usr/bin/env sh

sudo zypper install --no-confirm virtualbox
sudo usermod --append --groups vboxusers $USER
