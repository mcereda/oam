#!/usr/bin/env bash

set -e

sudo curl -fsSL https://get.docker.com | sh -
sudo usermod -aG docker ${USER}

# logout && login to apply the new status

docker run --rm --name test hello-world && docker rmi hello-world
