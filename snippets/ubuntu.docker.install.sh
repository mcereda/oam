#!/usr/bin/env sh
# source: https://docs.docker.com/engine/install/ubuntu/

export \
	DEBIAN_FRONTEND='noninteractive' \
	LC_ALL='C'

sudo apt --assume-yes purge docker docker-engine docker.io containerd runc

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update && sudo apt --assume-yes install docker-ce
