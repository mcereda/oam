# Bond network interfaces

Combines multiple network interfaces into a single logical interface.<br/>
Provides benefits such as increased bandwidth, redundancy, and load balancing.

1. [TL;DR](#tldr)
1. [Bonding modes](#bonding-modes)
1. [Configuration](#configuration)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Linux bonding is implemented through the `bonding` kernel module.<br/>
It implements several [bonding modes], each with its own characteristics and use cases.

If one's switches support LACP, prefer using mode 4 (802.3ad) for compatibility and optimal performance.<br/>
LACP allows the Linux system and the switch to negotiate the link aggregation settings automatically.

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<details>
  <summary>Usage</summary>

```sh
# Check the status of the bonding interface.
cat '/proc/net/bonding/bond0'

# Test the redundancy of the bonding interface.
# Simulates a failure of one of the slave interfaces.
ifconfig 'eth0' down; sleep 30s; ifconfig 'eth0' up
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Bonding modes

| ID  | Mode name                                  | Summary                                                                                                                                                                    | Use cases                                                                                                                         |
| --- | ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 0   | Round Robin                                | Sends packets out sequentially on each available slave interface.<br/>Provides load balancing across all used interfaces and increases the overall bandwidth.              | Environments where bandwidth aggregation is the primary goal and all connected switches support load balancing                    |
| 1   | Active-Backup                              | Only one slave interface is active at a time. If the active interface fails, the driver automatically switches to one of the backup interfaces.                            | Scenarios where redundancy is crucial, such as in mission-critical applications                                                   |
| 2   | XOR                                        | The driver uses a hash function to determine which slave interface to send a packet on. The hash is based on the source and destination MAC addresses.                     | Networks where the traffic patterns are relatively stable, and the same source-destination pairs are likely to be used frequently |
| 3   | Broadcast                                  | All packets are sent out on all slave interfaces. Provides high redundancy, but consumes a lot of network resources.                                                       |                                                                                                                                   |
| 4   | 802.3ad, Link Aggregation Control Protocol | Requires support from the connected switches. Creates a link aggregation group (LAG) between the Linux system and the switch. Provides both load balancing and redundancy. | Environments where high bandwidth and reliability are required                                                                    |
| 5   | Balance-TLB                                | Dynamically distributes **outgoing** traffic to the interface with the least load.                                                                                         | Environments where the traffic distribution is uneven and load balancing is required                                              |
| 6   | Balance-ALB                                | Distributes both outgoing and incoming traffic across all slave interfaces                                                                                                 | Networks where both high bandwidth and load balancing are required                                                                |

## Configuration

1. Load the `bonding` module:

   ```sh
   modprobe 'bonding'
   ```

1. Create a bonding interface.

   Add a configuration file in the `/etc/sysctl.d/` directory:

   ```conf
   # /etc/sysctl.d/bond0.conf
   # miimon: interval (in milliseconds) at which the bonding driver checks the link status of the slave interfaces
   bonding.modes=mode=6 miimon=100
   ```

1. Add the slave interfaces:

   ```conf
   # /etc/network/interfaces

   auto bond0
   iface bond0 inet static
       address <ip_address>
       netmask <netmask>
       gateway <gateway>
       bond-mode <mode_number>
       bond-miimon 100
       bond-slaves eth0 eth1
   ```

1. Restart the network service:

   ```sh
   sudo systemctl restart networking
   ```

## Further readings

### Sources

- [Understanding Linux Bonding Modes]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Bonding modes]: #bonding-modes

<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[Understanding Linux Bonding Modes]: https://linuxvox.com/blog/linux-bonding-modes/
