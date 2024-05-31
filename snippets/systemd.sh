#!/usr/bin/env sh

sudo systemctl enable --now 'gitlab-runner'
sudo journalctl -xefu 'gitlab-runner'
