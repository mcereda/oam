# Tailscale

Mesh VPN solution based on [WireGuard].

1. [TL;DR](#tldr)
1. [Access existing networks](#access-existing-networks)
   1. [Access VPCs in cloud providers](#access-vpcs-in-cloud-providers)
1. [Subnet routers](#subnet-routers)
   1. [Configure subnet routers](#configure-subnet-routers)
1. [Exit nodes](#exit-nodes)
1. [Specify search domains](#specify-search-domains)
1. [Override DNS servers](#override-dns-servers)
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

<details>
  <summary>Usage</summary>

```sh
# Connect hosts to the tailnet.
# Authenticates in the browser.
sudo tailscale up
sudo tailscale up --exit-node-allow-lan-access

# Find host's tailnet IPv4 address.
tailscale ip -4

# Show the recommended exit node.
tailscale exit-node suggest

# Use an exit node.
tailscale set --exit-node="$exit_node_id"
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Access existing networks

Configure one or more machines in that network to act as [subnet routers].

### Access VPCs in cloud providers

1. Create a VM in the subnet one is interested to connect.
1. Configure it to act as a [subnet router][subnet routers].

> [!tip]
> If the subnet the VM is in has routes to other subnets (A.K.A. the VM can connect to hosts in other subnets), only
> **one** subnet router VM is needed for all the connected subnets.

## Subnet routers

Refer [Subnet routers][tailscale  subnet routers].

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

Refer [Exit nodes][tailscale  exit nodes].

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

## Further readings

- [Website]
- [Codebase]
- [WireGuard]
- [Headscale]

### Sources

- [Documentation]
- [Subnet routers][tailscale  subnet routers]
- [Exit nodes][tailscale  exit nodes]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Exit nodes]: #exit-nodes
[Subnet routers]: #subnet-routers

<!-- Knowledge base -->
[Headscale]: headscale.md
[WireGuard]: wireguard.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/tailscale/tailscale
[Documentation]: https://tailscale.com/kb
[Mullvad exit nodes]: https://tailscale.com/kb/1258/mullvad-exit-nodes
[Set up a subnet router]: https://tailscale.com/kb/1019/subnets#set-up-a-subnet-router
[tailscale  exit nodes]: https://tailscale.com/kb/1103/exit-nodes
[tailscale  subnet routers]: https://tailscale.com/kb/1019/subnets
[Website]: https://tailscale.com/

<!-- Others -->
