# Kubectl

## TL;DR

```shell
# list resources
kubectl get pods
kubectl get pods -n kube-system coredns-845757d86-47np2
kubectl get namespaces --show-labels
kubectl get services -o wide

# start a pod
kubectl run nginx --image nginx

# taint a node
kubectl taint nodes node1 key1=value1:NoSchedule

# taint all nodes in a certain nodepool (azure aks)
kubectl get nodes \
  -l "agentpool=nodepool1" \
  -o jsonpath='{.items[*].metadata.name}'
| xargs -n1 -I{} -p kubectl taint nodes {} key1=value1:NoSchedule

# remove a taint
# notice the '-' sign at the end
kubectl taint nodes node1 key1=value1:NoSchedule-
```

## Further readings

- [Assigning Pods to Nodes]
- [Taints and Tolerations]
- [Commands reference]

[assigning pods to nodes]: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
[taints and tolerations]: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/

[commands reference]: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
