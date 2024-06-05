#!/usr/bin/env sh

kubectl create namespace 'gitlab'

kubectl apply --namespace 'gitlab' --values 'secrets.yaml'

# Requires the metrics server to be running in the cluster
kubectl top nodes
kubectl top pods

kubectl get events -n 'monitoring' --sort-by '.metadata.creationTimestamp'
