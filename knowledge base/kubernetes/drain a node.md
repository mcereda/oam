# Drain a K8S cluster node

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

1. mark the node as unschedulable (_cordon_):

   ```sh
   $ kubectl cordon 'kworker-rj2'
   node/kworker-rj2 cordoned
   ```

1. remove pods running on the node:

   ```sh
   $ kubectl drain 'kworker-rj2' --grace-period=300 --ignore-daemonsets=true
   node/kworker-rj2 already cordoned
   WARNING: ignoring DaemonSet-managed Pods: kube-system/calico-node-fl8dl, kube-system/kube-proxy-95vdf
   evicting pod default/my-dep-557548758d-d2pmd
   pod/my-dep-557548758d-d2pmd evicted
   node/kworker-rj2 evicted
   ```

1. do to the node what you need to do
1. make the node available again:

   ```sh
   $ kubectl uncordon 'kworker-rj2'
   node/kworker-rj2 uncordoned
   ```

## Further readings

- [Kubernetes]
- [`kubectl`][kubectl]

## Sources

All the references in the [further readings] section, plus the following:

- [How to drain a node in Kubernetes]

<!-- upstream -->
<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
[kubectl]: kubectl.md
[kubernetes]: README.md

<!-- external references -->
[how to drain a node in kubernetes]: https://linuxhandbook.com/kubectl-drain-node/
