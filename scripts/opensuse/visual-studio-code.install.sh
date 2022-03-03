#!/usr/bin/env sh

# source: https://en.opensuse.org/Visual_Studio_Code

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo zypper addrepo --refresh https://packages.microsoft.com/yumrepos/vscode vscode
sudo zypper install --no-confirm code
