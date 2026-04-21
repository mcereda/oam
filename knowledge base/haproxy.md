# HAProxy

> TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Serving certificates](#serving-certificates)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

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

## Serving certificates

Each `.pem` file should contain the private key, certificate, **and** any intermediate CA certificates **concatenated
together**.

Use the `bind … ssl crt` setting with a **single** TLS certificate to serve that certificate to **all** connections
regardless of SNI.

```cfg
bind :::443 v4v6 ssl crt /etc/haproxy/certificate.pem
```

To serve **different certs per domain**, one can either list multiple `crt` paths, or point to a directory containing
all of them. HAProxy will then use the client's SNI to pick and serve the related certificate automatically, without
requiring explicit SNI mapping.

```cfg
# multiple crt paths (individual certificate files)
bind *:443  ssl crt /etc/haproxy/certs/example.com.pem \
                crt /etc/haproxy/certs/api.example.com.pem \
                crt /etc/haproxy/certs/admin.example.com.pem \
                crt /etc/haproxy/certs/shop.example.com.pem

# crt dir path
bind *:8443 ssl crt /etc/haproxy/certs.d/

# mix
bind *:9443 ssl crt /etc/haproxy/certs.d/ crt /etc/haproxy/extra/wildcard.pem
```

If a client doesn't send SNI, or sends an unrecognized name, HAProxy falls back to the **first** certificate it loaded
(alphabetically, when using a directory).

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/haproxytech
[documentation]: https://www.haproxy.com/documentation/
[website]: https://www.haproxy.com/

<!-- Others -->
