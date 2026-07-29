# Tailscale

Mesh VPN solution based on [WireGuard].

1. [TL;DR](#tldr)
1. [Disable automatic update checks](#disable-automatic-update-checks)
1. [Access existing networks](#access-existing-networks)
   1. [Access VPCs in cloud providers](#access-vpcs-in-cloud-providers)
1. [Subnet routers](#subnet-routers)
   1. [Configure subnet routers](#configure-subnet-routers)
1. [Exit nodes](#exit-nodes)
1. [Tailscale Serve](#tailscale-serve)
1. [Tailscale Funnel](#tailscale-funnel)
1. [Taildrop](#taildrop)
1. [Tailscale SSH](#tailscale-ssh)
1. [Tags](#tags)
1. [MagicDNS](#magicdns)
    1. [HTTPS certificates](#https-certificates)
1. [Specify search domains](#specify-search-domains)
1. [Override DNS servers](#override-dns-servers)
1. [Split DNS (A.K.A. restricted nameservers)](#split-dns-aka-restricted-nameservers)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

Tailscale creates a peer-to-peer mesh network (called _tailnet_) instead of tunnelling all traffic through a central
server like traditional VPNs.<br/>
One can still use Tailscale like a traditional VPN by routing all traffic through an _exit node_.

Creating a tailnet requires signing up with Tailscale, which will act as the control server and administrative
console.<br/>
Alternatively, one could use [Headscale] to host their own control server.

Clients need to register with the tailnet's control server.

Devices on the tailnet are automatically assigned DNS names via [MagicDNS]. It allows one to access them by that name.

Access to existing resources in a network is granted by machines in that network acting as _subnet routers_.<br/>
This can be useful to access devices that do not support the Tailscale client, like printers.

<details>
  <summary>Setup</summary>

```sh
# Install.
brew install --cask 'tailscale-app'
pacman -S 'tailscale'

# Consider setting reverse path filtering to strict mode as a hardening measure.
# The kernel will accept packets from a source address only if a route back to the source address exists in the routing
# table.
# When using Tailscale as a subnet router or exit node, the value must be set to 2 (loose) or 0 (off) to allow packets
# to be forwarded from the Tailscale network.
# By default, these are set in /usr/lib/sysctl.d/50-default.conf.
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

# Start.
sudo systemctl enable --now 'tailscaled'
```

</details>

<details style='padding: 0 0 1rem 0'>
  <summary>Usage</summary>

```sh
# Connect hosts to the tailnet.
# Authenticates in the browser.
sudo tailscale up
sudo tailscale up --exit-node-allow-lan-access

# Find host's tailnet IPv4 address.
tailscale ip -4

# Disable MagicDNS on Linux.
tailscale set --accept-dns=false

# Show the recommended exit node.
tailscale exit-node suggest

# Use an exit node.
tailscale set --exit-node="$exit_node_id"

# Obtain TLS certificates.
tailscale cert <machine-name.tailnet-name.ts.net>

# Serve a local service running on port 3000.
tailscale serve 3000

# Serve a local directory.
tailscale serve /path/to/dir

# Show current serve configuration.
tailscale serve status

# Turn off serving.
tailscale serve off

# Expose a local service on port 3000 to the public internet.
tailscale funnel 3000

# Expose on an alternate allowed port.
tailscale funnel --https=8443 3000

# Turn off Funnel.
tailscale funnel off

# Send files.
tailscale file cp <files> <name-or-ip>:

# Receive files in the current directory.
sudo tailscale file get '.'

# Enable Tailscale SSH on a host.
tailscale set --ssh
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Disable automatic update checks

When installed via [Homebrew], the in-app toggle to check for updates does **not** seem to have any effect.

If installed from the Mac App Store, Tailscale's own settings are irrelevant and the App Store manages the updates.<br/>
One would need to disable auto-updates at the App Store level (_System Settings_ > _App Store_ > _Automatic Updates_),
or manage it via MDM.

Tailscale's standalone version uses the Sparkle framework for updates. It has two separate policy keys:

- `SUEnableAutomaticChecks` controls whether it periodically checks for updates.
- `SUAutomaticallyUpdate` controls whether it installs them automatically.

One can set these via MDM profile, or via `defaults write`:

```sh
defaults write 'io.tailscale.ipn.macsys' 'SUEnableAutomaticChecks' -bool false
defaults write 'io.tailscale.ipn.macsys' 'SUAutomaticallyUpdate' -bool false
```

Check the exact bundle identifier with `osascript -e 'id of app "Tailscale"'` before running the `defaults write`
commands.The defaults write approach bypasses the UI.

## Access existing networks

Configure one or more machines in that network to act as [subnet routers].

### Access VPCs in cloud providers

1. Create a VM in the subnet one is interested to connect.
1. Configure it to act as a [subnet router][subnet routers].

> [!tip]
> If the subnet the VM is in has routes to other subnets (A.K.A. the VM can connect to hosts in other subnets), only
> **one** subnet router VM is needed for all the connected subnets.

## Subnet routers

Refer [Subnet routers][documentation / subnet routers].

Subnet routers allow extending tailnets to include devices that don't or can't run the Tailscale client.<br/>
They act as gateways between the tailnet and physical subnets, enabling access and relaying traffic to and from devices,
networks, or services without needing to install Tailscale everywhere.

Subnet routers provide access to specific private subnets, but **do not** affect Internet traffic routing.<br/>
They are the appropriate solution if one needs to access private networks like office LANs or cloud VPCs.

To route **outbound** Internet traffic from tailnet devices, use [exit nodes] instead.<br/>
They effectively function as VPN servers, making one's traffic appears to come from the exit node's location.<br/>
This is useful to access geo-restricted content or improving privacy.

Subnet routers **do not** count toward one's pricing plan's device limit.

Any device that uses the subnet router as a gateway is considered _behind_ the subnet router.<br/>
Subnet routers use SNAT by default. When enabled, traffic from a device behind the subnet router appears to come from
the router itself, not the original device.<br/>
If preserving the original source IP address is important, one _can_ disable SNAT to maintain the original device's IP
address in the traffic packets.

### Configure subnet routers

Refer [Set up a subnet router].

Subnet routers need to be configured to allow IP forwarding as follows:

1. Enable forwarding.

   <details style='padding: 0 0 1rem 1rem'>
     <summary>Linux</summary>

   ```sh
   echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
   echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p /etc/sysctl.conf

   # If /etc/sysctl.d exists
   echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
   echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
   sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
   ```

   </details>

1. Allow forwarded traffic in the firewall

   <details style='padding: 0 0 1rem 1rem'>
     <summary>Linux</summary>

   ```sh
   firewall-cmd --permanent --add-masquerade
   ```

   </details>

1. Start advertising the tailnet's routes to the network:

   ```sh
   sudo tailscale set --advertise-routes='10.0.0.0/24,10.0.1.0/24,172.31.0.1/16'
   ```

1. Open the Access controls page of the Tailscale admin console and allow connectivity via the network by configuring
   them in the tailnet's policy file:

   ```json
   "grants": [
       {
           "src": ["john.doe@example.com"],
           "dst": [
               "10.0.0.0/24",
               "10.0.1.0/24",
               "172.31.0.1/16"
           ],
           "ip": ["*"]
       }
   ]
   ```

1. Accept advertised routes on **other** Linux-based local machines (**not** the subnet router).<br/>
   Non-Linux-based local machines can skip this step.

   ```sh
   sudo tailscale set --accept-routes
   ```

1. Ping one or more private IPs in the network from a host in the tailnet:

   ```sh
   $ ping '10.0.0.3' -t '3'
   PING 10.0.0.3 (10.0.0.3): 56 data bytes
   64 bytes from 10.0.0.3: icmp_seq=0 ttl=64 time=0.112 ms
   64 bytes from 10.0.0.3: icmp_seq=1 ttl=64 time=0.088 ms
   64 bytes from 10.0.0.3: icmp_seq=2 ttl=64 time=0.175 ms
   ```

## Exit nodes

Refer [Exit nodes][documentation / exit nodes].

Needed to route _outbound_ public Internet traffic.

Useful when one:

- Is in a coffee shop with untrusted Wi-Fi.
- Wants their traffic to appear from a specific location.
- Is traveling overseas and needs access to an online service (such as banking) only available in one's home
  country.

When configured, clients will make all connection to the destination through a device designated as an exit node.<br/>
When routing all traffic through an exit node, one is effectively using default routes (`0.0.0.0/0`, `::/0`), similarly
to how one would if they were using a typical VPN.

Exit nodes can be forced on devices.

By default, devices connecting to an exit node **will not** have access to their local network.<br/>
To allow a device to access its local network when routing traffic through an exit node, enable the
_Allow Local Network Access_ setting from the _Exit Nodes_ section of the devices' Tailscale client or by passing
`--exit-node-allow-lan-access` to `tailscale up` or `tailscale set`.

The Mullvad VPN add-on allows using Mullvad VPN servers as exit nodes.<br/>
Those exit nodes function similarly to regular exit nodes, but use Mullvad's pre-existing VPN infrastructure instead
of a privately owned device.<br/>
They support _most_ of the functionality of other exit nodes, but they do have some limitations.<br/>
Refer [Mullvad exit nodes].

## Tailscale Serve

Refer [Tailscale Serve][documentation / tailscale serve].

Tailscale Serve allows sharing a local service with other devices on the tailnet over HTTPS.<br/>
Useful for exposing a development server, internal tool, or web application to other tailnet members without the need to
configure port forwarding or firewall rules.

Serve requires [HTTPS certificates] to be enabled.

<details style='padding: 0 0 1rem 0'>
  <summary>Usage</summary>

```sh
# Serve a local service running on port 3000.
tailscale serve 3000

# Serve a local directory.
tailscale serve /path/to/dir

# Show current serve configuration.
tailscale serve status

# Turn off serving.
tailscale serve off
```

</details>

The same port **cannot** be used for both Serve and [Funnel] at the same time.<br/>
If the most recent command to configure the port was `serve`, the port will be completely private to the tailnet.

## Tailscale Funnel

Refer [Tailscale Funnel][documentation / tailscale funnel].

Extends [Serve] to share a process on the public internet. Lets anyone access a local service without needing Tailscale
themselves.<br/>
Traffic is routed through Tailscale's relay infrastructure with end-to-end encryption.

Funnel requires:

- Tailscale v1.38.3 or later.
- [MagicDNS] enabled.
- [HTTPS certificates] enabled.
- A `funnel` node attribute in the tailnet policy file.

Funnel can only listen on ports **443**, **8443**, and **10000**. All ports require TLS.

<details style='padding: 0 0 1rem 0'>
  <summary>Usage</summary>

```sh
# Expose a local service on port 3000 to the public internet.
tailscale funnel 3000

# Expose on an alternate allowed port.
tailscale funnel --https=8443 3000

# Turn off Funnel.
tailscale funnel off
```

</details>

Public DNS records can take up to 10 minutes to propagate for the tailnet domain.

> [!warning]
> Frequent certificate requests may exceed [Let's Encrypt]'s rate limits. It this case, one will need to wait 34 hours
> before retrying.

By default, the `funnel` node attribute is granted to `autogroup:member`.<br/>
One can restrict it to specific tagged devices in the tailnet policy file:

```json
"nodeAttrs": [
    {
        "target": ["tag:servers"],
        "attr": ["funnel"]
    }
]
```

## Taildrop

Refer [Taildrop][documentation / taildrop].

Taildrop allows sending files between personal devices on the tailnet over encrypted peer-to-peer connections using the
fastest available path.<br/>
It **cannot** send files to other users' devices, even if they are on the same tailnet.

<details style='padding: 0 0 1rem 0'>
  <summary>Usage</summary>

```sh
# Send files.
tailscale file cp <files> <name-or-ip>:

# Receive files in the current directory.
sudo tailscale file get '.'
```

</details>

Interrupted transfers can resume for up to one hour.

## Tailscale SSH

Refer [Tailscale SSH][documentation / tailscale ssh].

Manages SSH authentication and authorization through Tailscale's identity infrastructure. Eliminates the need to
distribute and manage SSH keys.<br/>
Connections are authenticated and encrypted over WireGuard using Tailscale node keys.

Intercepts traffic on port 22 for the Tailscale IP only. It does **not** modify the existing SSH configuration
(`/etc/ssh/sshd_config`) and keys (`~/.ssh/authorized_keys`).<br/>
At this time, the port **cannot** be changed from the default `22`.

```sh
# Enable Tailscale SSH on a host.
tailscale set --ssh
```

Both a network access rule and an SSH access rule must exist in the tailnet policy file.

> [!caution]
> Requiring re-authentication on every connection (`checkPeriod: "always"`) may cause issues with automation tools that
> open many SSH connections in a short time (like [Ansible]).

## Tags

Refer [Tags][documentation / tags].

They authenticate and identify non-user devices like servers, containers, or IoT devices.<br/>
They allow managing access control policies based on a device's purpose rather than the user who registered it.

A device **cannot** have both a user and a tag simultaneously. Adding a tag removes the associated user.<br/>
Tag owners are defined in the `tagOwners` section of the tailnet policy file, and only designated tag owners (or
Owners/Admins) can apply tags to devices.

```json
"tagOwners": {
    "tag:servers": ["group:devops"],
    "tag:monitoring": ["group:sre"]
}
```

## MagicDNS

Refer [MagicDNS][documentation / magicdns].

Automatically registers DNS names for every device in the tailnet. It allows accessing hosts by name instead of using IP
address.<br/>
Each device gets a fully qualified domain name. It combines the machine name and the tailnet's DNS name, e.g.
`monitoring.example-org.ts.net`.

Enabled by default on tailnets created after October 20, 2022.

Search domains are automatically added. One can usually access devices by just the machine name (e.g.
`ssh user@monitoring` instead of `ssh user@monitoring.example-org.ts.net`).

Shared devices from other tailnets require using the full domain name.

```sh
# Disable MagicDNS on Linux.
tailscale set --accept-dns=false
```

### HTTPS certificates

Refer [Enabling HTTPS].

Tailscale can automatically provision TLS certificates using [Let's Encrypt] for devices on the tailnet's `*.ts.net`
The certificate uses the DNS-01 challenge.<br/>
Required by [Serve] and [Funnel].

Enabling HTTPS publishes machine names and the tailnet DNS name on the public Certificate Transparency ledger.<br/>
One can use a randomized tailnet DNS name (e.g. `yak-bebop.ts.net`) to avoid publicizing organization names.

Certificates have a 90-day expiry and require periodic renewal.

```sh
# Obtain TLS certificates.
tailscale cert <machine-name.tailnet-name.ts.net>
```

## Specify search domains

Search domains provide a convenient way for users to access the tailnet's resources without having to specify the full
domain path every time they connect to any of them.

Admins can specify a list of domain suffixes that are automatically appended to any domain name that is not a FQDN.<br/>
Domains are searched in order.

## Override DNS servers

By default, devices in a tailnet prefer their local DNS settings, and only use the tailnet's DNS servers when needed.

Tailscale allows forcing any device in a tailnet to use tailnet-specific DNS settings instead of its local DNS
settings.<br/>
Preventing devices in a tailnet from using their local DNS settings might be useful to:

- Ensure devices have access to private DNS records.
- Prevent devices from using untrusted nameservers.
- Require all traffic to go through a specific DNS server that filters traffic.

To force tailnet devices to use the tailnet-defined DNS settings, enable the _Override DNS servers_ option under
_Global nameservers_.

> [!important]
> Make sure all devices in the tailnet have access to the global nameservers before forcing them to use the
> tailnet-specific DNS settings.<br/>
> Should ACLs or grants prevent a device from accessing the global nameservers, that device **will not** be able to
> resolve DNS queries.

Tailscale **cannot** guarantee that the DNS resolvers added to the _DNS_ page of the admin console will be queried
_in the exact order_ that one specified.<br/>
Depending on each DNS setting and operating system, Tailscale either proxies all DNS requests or defers to the
operating system.

Many modern operating systems have adopted complicated rules for how to optimize response time when multiple DNS
nameservers are available.<br/>
For example, operating systems might:

- Query nameservers in order, with small delays in between each attempt.
- Query all nameservers in parallel.
- Change the order of nameservers based on past performance.
- Change the order of nameservers based on known geographic proximity.
- Load balance queries between nameservers.

Should one need nameservers to be in a specific order, one is probably better off using the split DNS feature or
setting up conditional forwarding on one's private DNS service, and only using that resolver in their settings.

## Split DNS (A.K.A. restricted nameservers)

Tailscale's _split DNS_ feature (called _Restricted nameservers_ in the admin console) routes queries for specific
domains to specified nameserver, while all other queries continue to use the default resolver.

This is more reliable than OS-level per-domain resolver files (e.g. macOS `/etc/resolver/`) when Tailscale is running.
Tailscale's MagicDNS intercepts DNS queries **before** the OS resolver files are consulted for some domains, causing
timeouts rather than resolution failures.

Commonly used to resolve AWS internal load balancer hostnames from a developer machine over Tailscale.

<details style='padding: 0 0 1rem 1rem'>

Internal ELB DNS names (e.g. `internal-*.eu-west-1.elb.amazonaws.com`) are **publicly** resolvable, but return
**private** VPC IP addresses. To resolve them via the VPC DNS resolver (`172.31.0.2`) through the subnet router:

1. In Tailscale's admin console, go to _DNS_ > _Nameservers_ > _Add nameserver_ > _Custom_.
1. Enter `172.31.0.2` as the nameserver.
1. Enable _Restrict to domain_, and enter `elb.amazonaws.com`.
1. Save.

Tailscale will route `*.elb.amazonaws.com` queries through the subnet router to the VPC DNS resolver.

</details>

## Further readings

- [Website]
- [Codebase]
- [WireGuard]
- [Headscale]

### Sources

- [Documentation]
- [Subnet routers][documentation / subnet routers]
- [Exit nodes][documentation / exit nodes]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Exit nodes]: #exit-nodes
[Funnel]: #tailscale-funnel
[HTTPS certificates]: #https-certificates
[MagicDNS]: #magicdns
[Serve]: #tailscale-serve
[Subnet routers]: #subnet-routers

<!-- Knowledge base -->
[Ansible]: ansible.md
[Headscale]: headscale.md
[Homebrew]: homebrew.md
[Let's Encrypt]: letsencrypt.md
[Wireguard]: wireguard.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/tailscale/tailscale
[Documentation / exit nodes]: https://tailscale.com/kb/1103/exit-nodes
[Documentation / magicdns]: https://tailscale.com/docs/features/magicdns
[Documentation / subnet routers]: https://tailscale.com/kb/1019/subnets
[Documentation / tags]: https://tailscale.com/docs/features/tags
[Documentation / taildrop]: https://tailscale.com/docs/features/taildrop
[Documentation / tailscale funnel]: https://tailscale.com/docs/features/tailscale-funnel
[Documentation / tailscale serve]: https://tailscale.com/docs/features/tailscale-serve
[Documentation / tailscale ssh]: https://tailscale.com/docs/features/tailscale-ssh
[Documentation]: https://tailscale.com/kb
[Enabling HTTPS]: https://tailscale.com/docs/how-to/set-up-https-certificates
[Mullvad exit nodes]: https://tailscale.com/kb/1258/mullvad-exit-nodes
[Set up a subnet router]: https://tailscale.com/kb/1019/subnets#set-up-a-subnet-router
[Website]: https://tailscale.com/

<!-- Others -->
