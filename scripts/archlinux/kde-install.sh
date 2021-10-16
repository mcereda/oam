#!/bin/sh

sudo pacman --noconfirm \
	--sync --needed --noprogressbar --quiet --refresh \
	dolphin-plugins konsole plasma-desktop sddm \
	noto-fonts noto-fonts-cjk phonon-qt5-vlc \
	breeze-gtk discover drkonqi kdegraphics-thumbnailers kimageformats kinfocenter kscreen kwalletmanager packagekit-qt5 plasma-nm powerdevil pulseaudio xdg-desktop-portal-kde
sudo systemctl set-default graphical.target
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now sddm.service
sudo pacman --noconfirm --sync --clean --clean
