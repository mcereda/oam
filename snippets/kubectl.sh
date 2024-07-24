#!/usr/bin/env sh

kubectl create namespace 'gitlab'

kubectl create --namespace 'gitlab' secret generic 'gitlab-runner-token' --dry-run='client' --output 'yaml' \
	--from-literal='runner-registration-token=""' --from-literal='runner-token=glrt-…'
kubectl apply --namespace 'gitlab' --values 'secrets.yaml'


kubectl get nodes 'fargate-ip-172-31-83-147.eu-west-1.compute.internal' -o 'yaml' | yq -y '.metadata.labels'
kubectl get nodes -o jsonpath='{.items[].metadata.labels}' | yq -y

kubectl get events -n 'monitoring' --sort-by '.metadata.creationTimestamp'

# Requires the metrics server to be running in the cluster
kubectl top nodes
kubectl top pods


kubectl run --rm -it --image 'alpine' 'alpine' --command -- sh
kubectl run --rm -t --image 'amazon/aws-cli:2.17.16' 'awscli' -- autoscaling describe-auto-scaling-groups
kubectl -n 'kube-system' run --rm -it 'awscli' --overrides '{"spec":{"serviceAccountName":"cluster-autoscaler-aws"}}' \
	--image '012345678901.dkr.ecr.eu-west-1.amazonaws.com/cache/amazon/aws-cli:2.17.16' \
	autoscaling describe-auto-scaling-groups


kubectl scale deployment -n 'kube-system' 'cluster-autoscaler-aws-cluster-autoscaler' --replicas '0'
