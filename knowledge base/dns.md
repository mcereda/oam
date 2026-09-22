# Domain Name System

> TODO

Intro

1. [TL;DR](#tldr)
1. [Troubleshooting](#troubleshooting)
   1. [Some applications cannot resolve a `CNAME` record, while others can](#some-applications-cannot-resolve-a-cname-record-while-others-can)

## TL;DR

`CNAME` records are DNS-level aliases.\
TLS validation happens at the application layer against the **original** hostname the client requested (per SNI). Mind
the certificate used by the server answering the requests.

> [!warning] Records with TTL=0 might trigger misbehaviour in resolvers.
> Some resolvers like `mDNSResponder` (macOS's resolver daemon, used by `getaddrinfo()` and hence `ssh`) treat a 0-TTL
> record as _effectively uncacheable_, and (particularly for `CNAME` chains) **drop it** from their response to the
> application that requested the resolution instead of resolving it further or returning it at all.

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
# Resolve hostnames
nslookup 'google.com'
host 'google.com' '192.168.1.254'
dig 'google.com'
dig +short 'google.com' '@192.168.1.1'
# macOS
dscacheutil -q 'host' -a 'name' 'google.com'
scutil --dns | grep -B2 -A5 'lan'
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Troubleshooting

### Some applications cannot resolve a `CNAME` record, while others can

<details>
  <summary>Example</summary>

`git.lan` is configured as a `CNAME` of `forgejo.lan`, which resolves to `192.168.1.251`.

```sh
$ nslookup 'forgejo.lan'
Server:   192.168.1.254
Address:  192.168.1.254#53

Name:     forgejo.lan
Address:  192.168.1.251
$ nslookup 'git.lan'
Server:   192.168.1.254
Address:  192.168.1.254#53

Non-authoritative answer:
git.lan   canonical name = forgejo.lan.
Name:     forgejo.lan
Address:  192.168.1.251

$ dscacheutil -q 'host' -a 'name' 'forgejo.lan'
name: forgejo.lan
ip_address: 192.168.1.251
$ dscacheutil -q 'host' -a 'name' 'git.lan'      # <-- error code 1

$ ssh 'forgejo.lan' -vvvG
[…]
host forgejo.lan
hostname forgejo.lan
$ ssh 'git.lan' -vvvG
[…]
ssh: Could not resolve hostname git.lan: nodename nor servname provided, or not known
```

</details>

Possible causes:

- The `CNAME` record or its target have TTL=0.

  _Per DNS specification_, a TTL of **0** on any record tells resolvers to use its value **once** and to **not** cache
  it.\
  This is a known trigger for misbehavior in some resolvers like `mDNSResponder`, which treat a 0-TTL `CNAME` as a
  "non-answer" or a transient state. The resolver may refuse or fail to follow the chain, or to correlate the subsequent
  `A` record result back to the original request.

  Essentially, the resolver sees the TTL 0 on the alias and decides the information is too unstable to trust for the
  purpose of a redirection, causing it to return "not found" even though the destination is perfectly reachable.

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
