#!/bin/sh

sudo pacman --noconfirm \
	--sync --needed --refresh --noprogressbar \
	xfce4 xfce4-goodies lightdm-gtk-greeter
sudo systemctl set-default graphical.target
sudo systemctl enable --now lightdm
sudo pacman --noconfirm --sync --clean --clean
