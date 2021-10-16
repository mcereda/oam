#!/bin/sh

# https://linuxize.com/post/how-to-install-git-on-raspberry-pi/

sudo apt update
sudo apt install make libssl-dev libghc-zlib-dev libcurl4-gnutls-dev libexpat1-dev gettext

cd /usr/src/
sudo wget https://github.com/git/git/archive/refs/tags/v2.33.0.tar.gz -O git.tar.gz
sudo tar -xf git.tar.gz
cd git-*
sudo make prefix=/usr/local all
sudo make prefix=/usr/local install

git --version
