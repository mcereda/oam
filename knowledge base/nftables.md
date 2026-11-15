# nftables

Successor to [iptables].<br/>
Replaces the existing `iptables`, `ip6tables`, `arptables`, and `ebtables` framework.

Leverages the Linux kernel, and the newer `nft` userspace command line utility.<br/>
Provides a compatibility layer for the `iptables` framework.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Built on _rules_ which specify _actions_.<br/>
Rules are attached to _chains_.<br/>
Chains can contain a collection of rules, are stored inside _tables_, and are registered in netfilter's hooks.<br/>
Tables are specific for one of the layer 3 protocols.

Differently from [iptables], there are no predefined tables or chains.

`nft` supports replacing atomic rules by using `nft -f`.<br/>
This allows to conveniently manage rules using files.

> [!warning]
> When loading rules with `nft -f`, failures will result in none of the file's rules being loaded.<br/>
> Calling `nft` repeatedly (in a shell script or similar) will fail on specific rules.

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
# List tables.
nft list tables
nft list tables 'family_type'

# List all rules.
nft --handle list ruleset
nft -a list ruleset

# List chains and rules in tables.
nft list table 'family_type' 'table_name'

# List chains.
nft list chains
nft list chains 'family_type'

# List rules in chains.
nft list chain 'family_type' 'table_name' 'chain_name'

# Dry run commands.
nft --check …
nft -c …

# Be verbose.
nft --echo …
nft -e …

# Add chains.
nft add chain 'family_type' 'table_name' 'chain_name' \
  "{ type 'chain_type' hook 'hook_type' priority 'priority_value' ; policy 'policy' ;}"

# Edit chains.
nft chain 'family_type' 'table_name' 'chain_name' \
  "{ [ type 'chain_type' hook 'hook_type' device 'device_name' priority 'priority_value' ; policy 'policy_type' ; ] }"

# Add rules to chains.
nft add rule 'family_type' 'table_name' 'chain_name' 'handle' 'handle_value' 'statement'

# Delete rules.
nft delete rule inet 'base_table' 'input_filter' handle 3

# Clear rules from chains.
nft flush chain 'family_type' 'table_name' 'chain_name'

# Clear rules from tables.
nft flush table 'family_type' 'table_name'

# Delete chains.
# Chains can *only* be deleted if they contain no rules *and* they are not used as jump targets.
nft delete chain 'family_type' 'table_name' 'chain_name'

# Delete tables.
nft delete table 'inet' 'net_table'

# Remove the whole ruleset.
# This leaves the system with no firewall.
nft flush ruleset

# Dump the current ruleset.
nft --stateless list ruleset > '/path/to/nftables.dump'
nft -s list ruleset > '/path/to/nftables.dump'

# Read commands from files.
nft --file 'path/to/file'
nft -f 'path/to/file'

# Listen to all events.
# Reports in the native nft format.
nft monitor
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# List tables.
nft list tables
nft list tables 'ip'

# List tables' contents.
sudo nft list table 'ip' 'filter'

# Add tables for the IPv4 and IPv6 layers.
nft add table 'inet' 'net_table'

# Add tables for the ARP layer.
nft add table 'arp' 'arp_table'

# List chains.
nft list chains
nft list chains 'ip'

# List rules in chains.
nft list chain 'inet' 'base_table' 'input_filter'

# Add a base chain called 'input_filter' to the inet 'base_table' table.
# Register it to the 'input' hook with priority 0 and type 'filter'.
nft add chain 'inet' 'base_table' 'input_filter' "{type filter hook input priority 0;}"

# Edit chains.
nft chain 'inet' 'my_table' 'my_input' '{ policy drop ; }'

# Add rules to chains.
nft add rule 'inet' 'base_table' 'input_filter' tcp dport 80 drop
nft add rule 'ip' 'ssh' 'ssh_chain' tcp dport 22 accept
nft add rule 'inet' 'filter' 'input' log

# Delete chains.
nft delete chain 'inet' 'base_table' 'input_filter'


# Ensure LXC containers can connect to the Internet.
# Especially needed when Docker is also installed.
# 1. enables forwarding; 2. nats traffic from containers; 3. allows initiating traffic from containers; 4. allows
# responses.
# 10.0.3.0/24 -> LXC bridge subnet, enp1s0 -> host network interface, lxcbr0 -> LXC bridge network interface.
# Specifying an interface (e.g., iifname 'enp1s0') limits the rule to it. Leave them out to allow traffic on *all* of them.
sysctl -w 'net.ipv4.ip_forward=1' \
&& nft add table 'ip' 'nat' \
&& nft add chain 'ip' 'nat' postrouting '{ type nat hook postrouting priority srcnat; policy accept; }' \
&& nft add rule 'ip' 'nat' postrouting ip saddr '10.0.3.0/24' ip daddr != '10.0.3.0/24' oifname 'enp1s0' masquerade \
&& nft add table 'ip' 'filter' \
&& nft add chain 'ip' 'filter' forward '{ type filter hook forward priority filter; policy accept; }' \
&& nft add rule 'ip' 'filter' forward iifname 'lxcbr0' oifname 'enp1s0' accept \
&& nft add rule 'ip' 'filter' forward iifname 'enp1s0' oifname 'lxcbr0' ct state 'related,established' accept
```

</details>

## Further readings

- [`iptables`][iptables]
- [How to Create Secure Stateful Firewall Rules with nftables on Linux]

### Sources

- [Gentoo wiki]
- [Arch wiki]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[iptables]: iptables.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[Arch wiki]: https://wiki.archlinux.org/title/Nftables
[Gentoo wiki]: https://wiki.gentoo.org/wiki/Nftables
[How to Create Secure Stateful Firewall Rules with nftables on Linux]: https://www.pc-freak.net/blog/mastering-stateful-firewall-rules-nftables-ultimate-guide/
