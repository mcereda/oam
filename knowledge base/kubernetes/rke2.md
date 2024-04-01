# RKE2

Rancher Kubernetes Engine 2, Rancher's next-generation Kubernetes distribution.

Fully conformant Kubernetes distribution focusing on security and compliance within the U.S. Federal Government sector.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Keeps in close alignment with upstream Kubernetes.

RKE2 launches control plane components as static pods, managed by the kubelet.<br/>
It uses `containerd` as the embedded container runtime.

<details>
  <summary>Installation and configuration</summary>

```sh
curl -sfL 'https://get.rke2.io' | sudo sh - \
&& sudo systemctl enable --now 'rke2-server.service'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Use the provided `kubectl`.
export KUBECONFIG='/etc/rancher/rke2/rke2.yaml' \
/var/lib/rancher/rke2/bin/kubectl get pods

# Restore clusters from snapshots.
rke2 server --cluster-reset \
  --cluster-reset-restore-path="/var/lib/rancher/rke2/server/db/etcd-old-${BACKUP_DATE}"
```

</details>

<!-- Uncomment if needed
<details>
  <summary>Real world use cases</summary>
</details>
-->

## Further readings

- [Website]
- [K3S]

### Sources

- [When to use K3s and RKE2]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[k3s]: k3s.md

<!-- Files -->
<!-- Upstream -->
[website]: https://docs.rke2.io/
[when to use k3s and rke2]: https://www.suse.com/c/rancher_blog/when-to-use-k3s-and-rke2/

<!-- Others -->
