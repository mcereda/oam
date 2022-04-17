#!/usr/bin/env sh

sudo dnf install --assumeyes clamav clamd clamav-update
sudo setsebool -P antivirus_can_scan_system 1

sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl enable --now clamav-freshclam
