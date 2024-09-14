# K3S

Lightweight Kubernetes distribution built for IoT and Edge computing.

1. [TL;DR](#tldr)
1. [Packaged components](#packaged-components)
1. [Split roles on different nodes](#split-roles-on-different-nodes)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Starting the server with the `--cluster-init` option will start **all** control-plane components (including the
apiserver, controller-manager, scheduler, and `etcd`).<br/>
When using the embedded `etcd`, one will be able to disable specific components to split the control-plane and `etcd`
roles onto separate nodes.

<details>
  <summary>Setup</summary>

```sh
# Install as single-node server.
curl -sfL 'https://get.k3s.io' | sudo sh -
curl -sfL 'https://get.k3s.io' | sudo sh - server --token '12345'
# Install as agent node and add it to an existing cluster.
curl -sfL 'https://get.k3s.io' | K3S_URL='https://server.fqdn:6443' K3S_TOKEN='node-token' sudo sh -
# Install as node dedicated to the control plane.
curl -sfL 'https://get.k3s.io' \
| sudo sh -s - server --token 'node-token' --disable-etcd --server 'https://server.fqdn:6443'

# Disable the firewall (recommended).
systemctl disable firewalld --now
ufw disable
# Or open at least the required port and networks:
# Port 6443 --> apiserver, network 10.42.0.0/16 --> pods, network 10.43.0.0/16 --> services.
firewall-cmd --permanent --add-port '6443/tcp' \
&& firewall-cmd --permanent --zone='trusted' --add-source '10.42.0.0/16' \
&& firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16 \
&& firewall-cmd --reload
ufw allow '6443/tcp' && ufw allow from '10.42.0.0/16' to 'any' && ufw allow from '10.43.0.0/16' to 'any'

# Uninstall.
/usr/local/bin/k3s-uninstall.sh
/usr/local/bin/k3s-agent-uninstall.sh
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Check the configuration.
k3s check-config

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

## Packaged components

Refer [Managing packaged components].

Any file found on server nodes in `/var/lib/rancher/k3s/server/manifests` will automatically be deployed to the cluster
both on startup and when any file is changed on disk.<br/>
Deleting files from this directory will **not** delete the corresponding resources from the cluster.

Manifests are tracked as `AddOn` custom resources in the `kube-system` namespace.<br/>
Use `kubectl describe` on the `AddOn` resource to see errors or warnings encountered when applying the manifest files.

K3s comes with packaged components, deployed as `AddOns` via the manifests directory:

- `coredns`
- `traefik`
- `local-storage`
- `metrics-server`

The embedded `servicelb` LoadBalancer controller does not have a manifest file, but can be disabled as if it was one.

Manifests for packaged components are managed by K3s, and should not be altered.<br/>
These files are re-written to disk whenever K3s is started to ensure their integrity.

## Split roles on different nodes

This can only be done when using the embedded `etcd` component.

Refer [Managing server roles].

Procedure:

1. Dedicate the first server to `etcd` by starting k3s with all the other control plane components disabled:

   ```sh
   curl -sfL 'https://get.k3s.io' \
   | sh -s - server --cluster-init --disable-apiserver --disable-controller-manager --disable-scheduler
   ```

   This first node will start `etcd`, then wait for additional control-plane nodes to join.<br/>
   The cluster will **not** be usable until one joins an additional server with the control plane components enabled.

1. Create a server with only the control plane, by starting k3s with `etcd` disabled:

   ```sh
   curl -sfL 'https://get.k3s.io' \
   | sh -s - server --token 'node-token' --disable-etcd --server 'https://etcd-only.server.fqdn:6443'
   ```

1. Check the nodes have the correct roles:

   ```sh
   $ kubectl get nodes
   NAME           STATUS   ROLES                       AGE     VERSION
   k3s-server-1   Ready    etcd                        5h39m   v1.20.4+k3s1
   k3s-server-2   Ready    control-plane,master        5h39m   v1.20.4+k3s1
   ```

Add roles to existing dedicated nodes by restarting k3s on them with**out** the disable flags.

One can disable components in the `/etc/rancher/k3s/config.yaml` file instead of passing the options as CLI flags:

```yaml
cluster-init: true
disable-apiserver: true
disable-controller-manager: true
disable-scheduler: true
```

## Further readings

- [Website]
- [Documentation]
- [Kubernetes]
- [When to use K3s and RKE2]

### Sources

- The [Build your very own self-hosting platform with Raspberry Pi and Kubernetes] series of articles
- [Run Kubernetes on a Raspberry Pi with k3s]
- [Managing server roles]
- [Managing packaged components]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[kubernetes]: README.md

<!-- Upstream -->
[documentation]: https://docs.k3s.io/
[managing packaged components]: https://docs.k3s.io/installation/packaged-components
[managing server roles]: https://docs.k3s.io/installation/server-roles
[website]: https://k3s.io/
[when to use k3s and rke2]: https://www.suse.com/c/rancher_blog/when-to-use-k3s-and-rke2/

<!-- Others -->
[build your very own self-hosting platform with raspberry pi and kubernetes]: https://kauri.io/build-your-very-own-self-hosting-platform-with-raspberry-pi-and-kubernetes/5e1c3fdc1add0d0001dff534/c
[run kubernetes on a raspberry pi with k3s]: https://opensource.com/article/20/3/kubernetes-raspberry-pi-k3s
