#!/usr/bin/env sh

sudo systemctl enable --now 'gitlab-runner'

sudo journalctl -xefu 'gitlab-runner'
sudo journalctl --since 'yesterday'
sudo journalctl --since "2015-01-10 17:15:00"
sudo journalctl --since '09:00' --until "1 hour ago"
sudo journalctl --since "2015-01-10" --until "2015-01-11 03:00"

sudo hostnamectl
sudo hostnamectl status --static

sudo hostnamectl set-hostname --pretty 'prometheus'

sudo systemctl list-units --state='failed'

sudo systemctl hybrid-sleep && exit
