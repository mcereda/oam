# Kubectl

## TL;DR

```shell
# taint all nodes in a certain nodepool (azure aks)
kubectl get nodes \
  -l "agentpool=nodepool1" \
  -o jsonpath='{.items[*].metadata.name}'
| xargs -n1 -I{} -p kubectl taint nodes {} key1=value1:NoSchedule
```
