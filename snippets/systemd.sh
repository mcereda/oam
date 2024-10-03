#!/usr/bin/env sh

sudo systemctl enable --now 'gitlab-runner'
sudo journalctl -xefu 'gitlab-runner'

sudo hostnamectl
sudo hostnamectl status --static

sudo hostnamectl set-hostname --pretty 'prometheus'

sudo systemctl list-units --state='failed'
