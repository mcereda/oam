#!/usr/bin/env sh

sudo gpasswd -a 'user' 'vboxusers'
usermod --append --groups 'vboxusers'
