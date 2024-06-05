#!/usr/bin/env sh

helm repo list

helm repo add 'gitlab' 'https://charts.gitlab.io'

helm repo update
helm repo update 'keda'

helm search hub --max-col-width '100' 'ingress-nginx'
helm search repo --versions 'gitlab/gitlab-runner'

helm show values 'gitlab/gitlab'
helm show values 'gitlab/gitlab-runner' --version '0.64.1'

helm pull 'ingress-nginx/ingress-nginx' --version '4.0.6' --destination '/tmp' --untar --untardir 'ingress-nginx'

helm template --namespace 'gitlab' --values "values.gitlab-runner.yaml" --set global.hosts.hostSuffix='test' \
	'gitlab-runner' 'gitlab/gitlab-runner'

helm --namespace 'gitlab' upgrade --install --create-namespace --version '0.64.1' 'gitlab-runner' \
	--values 'values.gitlab-runner.yml' 'gitlab/gitlab-runner'
helm upgrade --install 'keda' 'keda' --repo 'https://kedacore.github.io/charts' --namespace 'keda' --create-namespace

helm get manifest 'wordpress'

helm -n 'monitoring' delete 'grafana'

helm plugin list
