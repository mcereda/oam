#!/usr/bin/env bash

# https://k3s.io/

curl -sfL 'https://get.k3s.io' | sh -
curl 'https://github.com/k3s-io/k3s/releases/download/v1.19.7%2Bk3s1/k3s' \
	--location --remote-name

# Allow the 'wheel' group to manage the cluster.
sudo chown 'root:wheel' '/etc/rancher/k3s/k3s.yaml'
sudo chmod 'g+r' '/etc/rancher/k3s/k3s.yaml'

# Use tools as a normal user.
ln -s '/etc/rancher/k3s/k3s.yaml' "${HOME}/.kube/config"

sudo k3s server &
# Kubeconfig is written to /etc/rancher/k3s/k3s.yaml
sudo k3s kubectl get node

# On a different node run the below.
# NODE_TOKEN comes from /var/lib/rancher/k3s/server/node-token on your server
sudo k3s agent --server 'https://myserver:6443' --token "${NODE_TOKEN}"
curl -sfL 'https://get.k3s.io' | K3S_URL='https://server:6443' K3S_TOKEN='node-token' sh -
