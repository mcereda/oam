# Mullvad VPN

> TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Public DNS](#public-dns)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

One can use the same account on up to 5 different devices.<br/>
When logging in with accounts that already have 5 devices associated with it, the application will show a list of
devices and prompt to log out of at least one of them.

Enable _local network sharing_ to access other devices on the same _local_ network (e.g. NAS).<br/>
Use the IP address of the device when connecting to it in case the hostname is not resolved correctly.

Use [split tunneling][Documentation / Split tunneling with the Mullvad app] to _exclude_ some apps from the VPN while it
is active.

Consider using [Mullvad's public encrypted DNS service][Documentation / DNS over HTTPS and DNS over TLS] as upstream for
DNS forwarders (like [Pi-hole]), or when not connected to Mullvad's VPN service.

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Public DNS

Refer to [DNS over HTTPS and DNS over TLS][documentation / dns over https and dns over tls].

Mullvad offers a public encrypted DNS service. It is primarily meant to be used when one is **not** using the VPN, by
devices that cannot or should not be using the VPN, or by non-customers.

When connected to Mullvad's VPN, using the public DNS will always be slower than directly using the DNS resolver on the
VPN server that one is connected to.

It uses DNS over HTTPS (DoH) and DNS over TLS (DoT). DNS queries are encrypted between the source device and the DNS
servers.

The servers resolve queries while giving clients as little information as possible about other DNS servers and the
queries involved in the resolving process.

Depending on the server used, the service can provide basic content blocking for ads, trackers, malware, adult content,
gambling and social media.

DNS queries are meant to be routed to the geographically closest server. Peering and routing between Internet providers
might affect this.<br/>
Should the closest server closest be completely offline, queries will be routed to the next closest one.

A **limited** DNS resolver is listening on port 53 (UDP and TCP). This only resolves hostnames related to this service
(`dns.mullvad.net`, `adblock.mullvad.net`, etc). Clients can resolve the IP of the resolver before querying it over
encrypted DNS.

| Hostname                 | Ads     | Trackers | Malware | Adult   | Gambling | Social media |
| ------------------------ | ------- | -------- | ------- | ------- | -------- | ------------ |
| dns.mullvad.net          |         |          |         |         |          |              |
| adblock.dns.mullvad.net  | blocked | blocked  |         |         |          |              |
| base.dns.mullvad.net     | blocked | blocked  | blocked |         |          |              |
| extended.dns.mullvad.net | blocked | blocked  | blocked |         |          | blocked      |
| family.dns.mullvad.net   | blocked | blocked  | blocked | blocked | blocked  |              |
| all.dns.mullvad.net      | blocked | blocked  | blocked | blocked | blocked  | blocked      |

| Hostname                 | IPv4 address | IPv6 address | DoH port | DoT port |
| ------------------------ | ------------ | ------------ | -------- | -------- |
| dns.mullvad.net          | 194.242.2.2  | 2a07:e340::2 | 443      | 853      |
| adblock.dns.mullvad.net  | 194.242.2.3  | 2a07:e340::3 | 443      | 853      |
| base.dns.mullvad.net     | 194.242.2.4  | 2a07:e340::4 | 443      | 853      |
| extended.dns.mullvad.net | 194.242.2.5  | 2a07:e340::5 | 443      | 853      |
| family.dns.mullvad.net   | 194.242.2.6  | 2a07:e340::6 | 443      | 853      |
| all.dns.mullvad.net      | 194.242.2.9  | 2a07:e340::9 | 443      | 853      |

IPs can only be used with DNS resolvers that **do** support DoH or DoT. They will **not** work for DNS over ports
`UDP/53` or `TCP/53`.

Check by going to <https://mullvad.net/check>. It should show no DNS leaks.

## Further readings

- [Website]
- [Codebase]
- [Documentation]
- [Blog]

### Sources

- [Documentation / Using the Mullvad VPN app]
- [Documentation / DNS over HTTPS and DNS over TLS]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Pi-hole]: pi-hole.md

<!-- Files -->
<!-- Upstream -->
[Blog]: https://mullvad.net/en/blog
[Codebase]: https://github.com/mullvad/
[Documentation / DNS over HTTPS and DNS over TLS]: https://mullvad.net/en/help/dns-over-https-and-dns-over-tls
[Documentation / Split tunneling with the Mullvad app]: https://mullvad.net/en/help/split-tunneling-with-the-mullvad-app
[Documentation / Using the Mullvad VPN app]: https://mullvad.net/en/help/using-mullvad-vpn-app
[Documentation]: https://mullvad.net/en/help/
[Website]: https://mullvad.net/en/

<!-- Others -->
