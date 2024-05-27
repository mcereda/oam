# Proxy

Application acting as an intermediary between a client requesting a resource and the server providing that resource.<br/>
It may reside on one's local host or at any point between it and destination servers on the Internet.

Proxy servers passing unmodified requests and responses are usually called _gateways_ or _tunneling proxies_.<br/>
_Anonymous_ proxies reveal their identity as proxy servers but do not disclose the originating IP address of clients.<br/>
_Transparent_ proxies identify themself as proxy servers but also give the originating IP address away using HTTP header
fields like `X-Forwarded-For`.

1. [Forwarding proxy](#forwarding-proxy)
1. [Reverse proxy](#reverse-proxy)
1. [Further readings](#further-readings)

## Forwarding proxy

Internet-facing proxies used to retrieve and eventually cache data from a wide range of sources (in most cases, anywhere
on the Internet).

## Reverse proxy

Proxy servers that accept connections from clients, forward them to one or more backend servers to handle the requests,
and return the response as if it came directly from them.<br/>
This should leave the clients with no knowledge of the backend servers.

Reverse proxies commonly perform load-balancing, authentication, decryption and caching.

## Further readings

Reverse proxies:

- [Nginx]
- [Traefik]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[nginx]: nginx.md
[traefik]: traefik.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
