# K3S

Lightweight Kubernetes distribution built for IoT and Edge computing.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation and configuration</summary>

```sh
curl -sfL 'https://get.k3s.io' | sudo sh -
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Use the provided `kubectl`.
k3s kubectl get pods

# Restore clusters from snapshots.
k3s server --cluster-reset \
  --cluster-reset-restore-path="/var/lib/rancher/k3s/server/db/etcd-old-${BACKUP_DATE}"
```

</details>

<!-- Uncomment if needed
<details>
  <summary>Real world use cases</summary>
</details>
-->

## Further readings

- [Website]
- [Documentation]
- [Kubernetes]
- [When to use K3s and RKE2]

### Sources

- The [Build your very own self-hosting platform with Raspberry Pi and Kubernetes] series of articles
- [Run Kubernetes on a Raspberry Pi with k3s]

<!--
  References
  -->

<!-- Knowledge base -->
[kubernetes]: README.md

<!-- Upstream -->
[documentation]: https://docs.k3s.io/
[website]: https://k3s.io/
[when to use k3s and rke2]: https://www.suse.com/c/rancher_blog/when-to-use-k3s-and-rke2/

<!-- Others -->
[build your very own self-hosting platform with raspberry pi and kubernetes]: https://kauri.io/build-your-very-own-self-hosting-platform-with-raspberry-pi-and-kubernetes/5e1c3fdc1add0d0001dff534/c
[run kubernetes on a raspberry pi with k3s]: https://opensource.com/article/20/3/kubernetes-raspberry-pi-k3s
