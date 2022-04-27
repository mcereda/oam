#!/usr/bin/env sh

sudo zypper install --no-confirm https://prerelease.keybase.io/keybase_amd64.rpm
systemctl --user enable --now keybase.service
systemctl --user enable --now kbfs.service
