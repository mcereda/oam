#!/usr/bin/env sh

# Set Gitea up in Kubernetes
kubectl --namespace 'gitea' create secret generic 'gitea-admin-secret' \
	--from-literal 'username=gitea_admin' --from-literal "password=Scribble0-Tray1-Finisher4"
helm upgrade -i -n 'gitea' --create-namespace --repo 'https://dl.gitea.com/charts/' 'gitea' 'gitea' -f 'values.yaml'

# Access the container when using docker compose
docker exec -ti 'gitea-server-1' sh

# Generate self-signed certificates
gitea cert --host 'gitea.lan'

# List organizations
curl -fsSL -H 'Authorization: token abcdef0123456789abcdef0123456789abcdef01' 'https://gitea.example.org/api/v1/orgs'

# Get repository information
curl -fsSL -H 'Authorization: token a…1' 'https://gitea.example.org/api/v1/repos/john/templates'
