#!/usr/bin/env sh

flatpak remote-add \
	--user --if-not-exists \
	flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --or-update --user \
	--noninteractive --assumeyes \
	flathub com.bitwarden
