#!/usr/bin/env sh

helm repo list

helm repo add 'gitlab' 'https://charts.gitlab.io'

helm repo update
helm repo update 'keda'

helm search hub --max-col-width '100' 'ingress-nginx'
helm search repo --versions 'gitlab/gitlab-runner'

# Get the chart version for specific app versions.
helm search repo --versions --output 'json' … \
| jq -r '.[]|select(.app_version=="17.9.0").version' -
# Get the latest chart version matching partial app versions.
helm search repo --versions --output 'json' … \
| jq -r 'map(select(.app_version|test("7.8")))|first.version' -

helm show values 'gitlab/gitlab'
helm show values 'gitlab/gitlab-runner' --version '0.64.1'

helm pull 'ingress-nginx/ingress-nginx' --version '4.0.6' --destination '/tmp' --untar --untardir 'ingress-nginx'

helm template --namespace 'gitlab' --values "values.gitlab-runner.yaml" --set global.hosts.hostSuffix='test' \
	'gitlab-runner' 'gitlab/gitlab-runner'

helm --namespace 'gitlab' upgrade --install --create-namespace --version '0.64.1' 'gitlab-runner' \
	--values 'values.gitlab-runner.yml' 'gitlab/gitlab-runner' --dry-run='server'
helm upgrade --install 'keda' 'keda' --repo 'https://kedacore.github.io/charts' --namespace 'keda' --create-namespace
helm upgrade --install … --atomic --cleanup-on-fail

helm list -n 'default'
helm list -A

helm get manifest 'wordpress'
helm --namespace 'kube-system' get values 'metrics-server'

helm -n 'monitoring' delete 'grafana'

helm plugin list

helm plugin install 'https://github.com/databus23/helm-diff'
helm -n 'pocs' diff upgrade --repo 'https://dl.gitea.com/charts/' 'gitea' 'gitea' -f 'values.yaml'

aws eks --region 'eu-west-1' update-kubeconfig --name 'custom-eks-cluster' \
&& helm --namespace 'kube-system' upgrade --install --repo 'https://kubernetes.github.io/autoscaler'
	'cluster-autoscaler' 'cluster-autoscaler' \
	--set 'cloudProvider'='aws' --set 'awsRegion'='eu-west-1' --set 'autoDiscovery.clusterName'='custom-eks-cluster' \
	--set 'rbac.serviceAccount.name'='cluster-autoscaler-aws' \
	--set 'replicaCount'='2' \
	--set 'resources.requests.cpu'='40m' --set 'resources.requests.memory'='50Mi' \
	--set 'resources.limits.cpu'='100m' --set 'resources.limits.memory'='300Mi' \
	--set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight'='100' \
	--set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.topologyKey'='kubernetes.io/hostname' \
	--set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].key'='app.kubernetes.io/name' \
	--set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].operator'='In' \
	--set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].values[0]'='aws-cluster-autoscaler'

helm --namespace 'kube-system' diff upgrade 'metrics-server' 'metrics-server/metrics-server' \
	--version '3.12.2' --values 'metrics-server.values.yml' \
	--set 'args[0]'='--kubelet-insecure-tls'
