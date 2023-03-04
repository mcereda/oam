#!/usr/bin/env sh

sudo zypper install --no-confirm \
	boinc-client \
	boinc-manager

sudo usermod --append --groups boinc "$USER"

# stop computation when user active
xhost +SI:localuser:boinc

# virtualbox integration
command VBoxManage --version >/dev/null && sudo usermod --append --groups vboxusers boinc

# amdgpu integration
# https://en.opensuse.org/SDB:AMDGPU
# https://amdgpu-install.readthedocs.io/en/latest/install-installing.html
amdgpu-install --usecase=workstation --opencl=rocr
