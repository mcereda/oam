#!/usr/bin/env sh

docker exec -ti 'gitea-server-1' sh

kubectl --namespace 'gitea' create secret generic 'gitea-admin-secret' \
	--from-literal 'username=gitea_admin' --from-literal "password=Scribble0-Tray1-Finisher4"
helm upgrade -i -n 'gitea' --create-namespace --repo 'https://dl.gitea.com/charts/' 'gitea' 'gitea' -f 'values.yaml'
