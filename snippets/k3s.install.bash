#!/usr/bin/env bash

# https://k3s.io/

set -e

curl "https://github.com/k3s-io/k3s/releases/download/v1.19.7%2Bk3s1/k3s" \
	--location --remote-name

sudo k3s server &
# Kubeconfig is written to /etc/rancher/k3s/k3s.yaml
sudo k3s kubectl get node

# On a different node run the below.
# NODE_TOKEN comes from /var/lib/rancher/k3s/server/node-token on your server
sudo k3s agent --server https://myserver:6443 --token ${NODE_TOKEN}
