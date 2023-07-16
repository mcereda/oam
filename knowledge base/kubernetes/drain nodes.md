# Drain nodes in K8S clusters

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

1. **Cordon** the Nodes.<br/>
   This marks each Node as _unschedulable_ and prevents new Pods to start on them.

   ```sh
   $ kubectl cordon 'kworker-rj2'
   node/kworker-rj2 cordoned
   ```

1. **Drain** the nodes.<br/>
   This _evicts_ Pods already running on the Nodes.

   ```sh
   $ kubectl drain 'kworker-rj2' --grace-period=300 --ignore-daemonsets=true
   node/kworker-rj2 already cordoned
   WARNING: ignoring DaemonSet-managed Pods: kube-system/calico-node-fl8dl, kube-system/kube-proxy-95vdf
   evicting pod default/my-dep-557548758d-d2pmd
   pod/my-dep-557548758d-d2pmd evicted
   node/kworker-rj2 evicted
   ```

1. Do to the Nodes what you need to do.
1. **Uncordon** the Nodes.
   This makes them available for scheduling again.

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

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[kubectl]: kubectl.md
[kubernetes]: README.md

<!-- Others -->
[how to drain a node in kubernetes]: https://linuxhandbook.com/kubectl-drain-node/
