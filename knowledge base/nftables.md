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
nft list tables inet

# Add tables for the IPv4 and IPv6 layers.
nft add table inet 'net_table'

# Add tables for the ARP layer.
nft add table arp 'arp_table'

# Add a base chain called 'input_filter' to the inet 'base_table' table.
# Register it to the 'input' hook with priority 0 and type 'filter'.
nft add chain inet 'base_table' 'input_filter' "{type filter hook input priority 0;}"

# List all rules.
nft -a list ruleset

# List rules in chains.
nft list chain inet 'base_table' 'input_filter'

# Add rules to chains.
nft add rule inet 'base_table' 'input_filter' tcp dport 80 drop

# Delete rules.
nft delete rule inet 'base_table' 'input_filter' handle 3

# Delete chains.
# Chains can *only* be deleted if they contain no rules *and* they are not used as jump targets.
nft delete chain inet base_table input_filter

# Delete tables.
nft delete table inet 'net_table'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [`iptables`][iptables]

### Sources

- [Gentoo wiki]

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
[Gentoo wiki]: https://wiki.gentoo.org/wiki/Nftables
