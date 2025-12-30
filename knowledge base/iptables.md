# Iptables

> [!warning]
> It should be replaced with its successor, [`nftables`][nftables].

Command line utility for configuring the Linux kernel-level firewall implemented within the netfilter project.

Inspects, modifies, forwards, redirects, and/or drops IP packets based on _rules_.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Use `iptables` for IPv4 and `ip6tables` for IPv6.<br/>
They have the same syntax, but some options are specific to either IPv4 or IPv6.

Rules are generally split up in three sections (A.K.A. _chains_):

- _INPUT_ manages all packets destined for the local host.
- _FORWARD_ manages all packets that are passing through.<br/>
  This chain is usually given rules when the local host is used as a router.
- _OUTPUT_ manages all packets originating from the local host.

Rules are applied to a packed, depending on the packet's direction and _**in the order the rules are specified**_.<br/>
Should no specific rule apply, the packet is applied the default policy for the chain.

Chains must be referenced using their **uppercase** name.

Each chain has its own default policy, and it can either be `ACCEPT` or `DROP`.<br/>
Rules can then be implemented to configure exceptions to the default policy.<br/>
Rules can either be _appended_ (`-A`) to the bottom a chain or _inserted_ (`-I`). When no rule is specified during
insertion, that rule is inserted on the top of the chain.

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
# List current rules.
iptables -L
iptables -L --line-numbers

# Add rules.
iptables -I 'INPUT' -p 'tcp' --dport '443' -j 'ACCEPT'
iptables -I 'INPUT' -p 'tcp' -s '192.168.100.100' --dport 22 -j 'ACCEPT'
iptables -I 'INPUT' -p 'tcp' -s '!192.168.100.0/24' --dport 22 -j 'REJECT'

# Change default policies to 'DROP'.
iptables -P 'FORWARD' 'DROP'

# Delete specific rules.
iptables -D 'INPUT' 2

# Delete *all* rules.
iptables -F

# Backup and restore rules.
iptables-save -f '/etc/iptables/rules.v4'
iptables-restore '/etc/iptables/rules.v4'
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

- [`nftables`][nftables]
- [How to set up a stateful firewall with iptables]
- [Simple stateful firewall]

### Sources

- [Iptables basics]
- [Archlinux wiki]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[nftables]: nftables.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[Archlinux wiki]: https://wiki.archlinux.org/title/Iptables
[How to set up a stateful firewall with iptables]: https://evilshit.wordpress.com/2013/12/17/how-to-set-up-a-stateful-firewall-with-iptables/
[Iptables basics]: https://www.worldstream.com/nl/article/iptables-basics/
[Simple stateful firewall]: https://wiki.archlinux.org/title/Simple_stateful_firewall
