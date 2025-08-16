#!/usr/bin/env sh

# Manage namespaces
kubectl create namespace 'gitlab'

# Manage secrets
kubectl apply --namespace 'gitlab' --values 'secrets.yaml'
kubectl create --namespace 'gitlab' secret generic 'gitlab-runner-token' --dry-run='client' --output 'yaml' \
	--from-literal='runner-registration-token=""' --from-literal='runner-token=glrt-…'
kubectl --namespace 'gitea' create secret generic 'gitea-admin-secret' \
	--from-literal 'username=gitea_admin' --from-literal "password=$(pulumi config get 'giteaAdminPassword')"
kubectl get secrets -n 'gitea' 'gitea' -o jsonpath='{.data.config_environment\.sh}' | base64 -d
kubectl get secrets -n 'gitea' 'gitea-inline-config' -o go-template='{{.data.mailer|base64decode}}'

# Manage nodes
kubectl get nodes 'fargate-ip-172-31-83-147.eu-west-1.compute.internal' -o 'yaml' | yq -y '.metadata.labels'
kubectl get nodes -o jsonpath='{.items[].metadata.labels}' | yq -y

# Manage events
kubectl get events -n 'monitoring' --sort-by '.metadata.creationTimestamp'

# See resources utilization
# Requires the metrics server to be running in the cluster
kubectl top nodes
kubectl top pods

# Create containers
kubectl run --image 'busybox' 'busybox' --dry-run='server' --output 'yaml'
kubectl run --rm -it --image 'alpine' 'alpine' --command -- sh
kubectl run --rm -it --image 'amazon/aws-cli:2.17.16' 'awscli' -- autoscaling describe-auto-scaling-groups
kubectl -n 'kube-system' run --rm -it 'awscli' --overrides '{"spec":{"serviceAccountName":"cluster-autoscaler-aws"}}' \
	--image '012345678901.dkr.ecr.eu-west-1.amazonaws.com/cache/amazon/aws-cli:2.17.16' \
	autoscaling describe-auto-scaling-groups

# Execute commands in running containers
kubectl exec 'some-pod' -- env
kubectl -n 'gitea' exec 'deploy/gitea' -c 'gitea' -- env

# Scale deployments
kubectl scale deployment -n 'kube-system' 'cluster-autoscaler-aws-cluster-autoscaler' --replicas '0'

# Add annotations
kubectl annotate sc 'gp2' 'storageclass.kubernetes.io/is-default-class'='false'
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
    annotations:
        storageclass.kubernetes.io/is-default-class: "true"
    name: gp3
parameters:
    type: gp3
provisioner: kubernetes.io/aws-ebs
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

# Check persistent volumes' usage
# Need to connect to the pod mounting it
kubectl -n 'gitea' exec 'gitea-766fd5fb64-2qlqb' -c 'gitea' -- df -h '/data'

# Create a fictious job large enough to trigger a scale up in clusters with cluster-autoscaler
kubectl run --rm -i --restart 'Never' --image='busybox' 'resource-grabber' --override-type 'strategic' \
	--overrides '{"spec":{"containers":[{"name":"main","resources":{"requests":{"cpu":"1700m"}}}]}}' \
	-- \
	sleep '3s'

# Remove nodes safely
kubectl cordon 'kworker-rj2' \
&& kubectl drain 'kworker-rj2' --grace-period=300 --ignore-daemonsets=true \
&& kubectl delete node 'kworker-rj2'

# Get raw information as JSON
kubectl get --raw "/api/v1/nodes/ip-172-31-69-42.eu-west-1.compute.internal/proxy/stats/summary"
# Get raw information as Prometheus metrics
kubectl get --raw "/api/v1/nodes/ip-172-31-69-42.eu-west-1.compute.internal/proxy/metrics/cadvisor"

# Get ephemeral storage usage for pods
kubectl get --raw "/api/v1/nodes/ip-172-31-69-42.eu-west-1.compute.internal/proxy/stats/summary" \
| jq '.pods[] | select(.podRef.name == "gitlab-runner-59dd68c5cb-9vcp4")."ephemeral-storage"'
# Dynamic way for the same action
POD_NAME='gitlab-runner-6ddd58fcb6-c9swk' POD_NAMESPACE='gitlab' \
&& kubectl get pods -n "$POD_NAMESPACE" "$POD_NAME" -o jsonpath='{.status.hostIP}' | tr '.' '-' \
| xargs -I '%%' kubectl get --raw '/api/v1/nodes/ip-%%.eu-west-1.compute.internal/proxy/stats/summary' \
| jq --arg 'podName' "$POD_NAME" '.pods[] | select(.podRef.name == $podName)."ephemeral-storage"'

# Show changes from the live version against a would-be applied version
kubectl kustomize 'https://github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller' \
| kubectl diff -f -
kubectl diff -k 'external-snapshotter'
