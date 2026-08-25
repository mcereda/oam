# HAProxy

Open-source, high-performance TCP/HTTP load balancer and reverse proxy.
Uses an event-driven, non-blocking architecture. It can handle up to millions of concurrent connections with minimal
resource consumption.

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Load balancing](#load-balancing)
1. [Health checks](#health-checks)
1. [ACLs](#acls)
1. [Stick tables](#stick-tables)
1. [Logging](#logging)
1. [Stats and runtime API](#stats-and-runtime-api)
1. [Serving certificates](#serving-certificates)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install.
apt install haproxy
brew install haproxy

# Check the installed version and build options.
haproxy -vv
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Validate a configuration file.
haproxy -c -f '/etc/haproxy/haproxy.cfg'

# Start with a specific configuration file.
haproxy -f '/etc/haproxy/haproxy.cfg'

# Reload without dropping connections.
systemctl reload haproxy

# Query runtime stats via the socket.
echo 'show info' | socat '/run/haproxy/admin.sock' -
echo 'show stat' | socat '/run/haproxy/admin.sock' -

# Disable a backend server at runtime.
echo 'disable server some-backend/server1' | socat '/run/haproxy/admin.sock' -
```

</details>

## Configuration

The configuration file is split into the following section types:

| Section    | Summary                                                                                                                                                                                                                                              |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `global`   | Process-wide settings (user, group, chroot, max connections, log targets, SSL defaults).                                                                                                                                                             |
| `defaults` | Values inherited by all following frontends, backends, and listeners (unless overridden). `defaults` blocks applies only to those sections that come after them in the file. New `defaults` blocks do **not** inherit values from the previous ones. |
| `frontend` | How client requests are received. Binds to addresses and ports, applies client-side rules, and routes to backends.                                                                                                                                   |
| `backend`  | A pool of servers and their load balancing strategy.                                                                                                                                                                                                 |
| `listen`   | Combines a frontend and backend into a single section. Useful for simple TCP proxies or the stats dashboard.                                                                                                                                         |

<details style='padding: 0 0 1rem 0'>
  <summary>Example</summary>

```cfg
global
    maxconn 4096
    log 127.0.0.1:514 local0 info
    stats socket /run/haproxy/admin.sock mode 660 level admin

defaults
    mode http
    timeout connect 5s
    timeout client 30s
    timeout server 30s

frontend http_in
    bind *:80
    default_backend app_servers

backend app_servers
    balance roundrobin
    server app1 192.168.1.10:8080 check
    server app2 192.168.1.11:8080 check
```

</details>

Validate the configuration offline before deploying with `haproxy -c -f /etc/haproxy/haproxy.cfg`.

A `frontend` without a `default_backend` or any `use_backend` rule will still accept connections, but only return 503.

## Load balancing

Set the algorithm with the `balance` directive in a `backend` or `listen` section.

| Algorithm    | Behavior                                                 | Use case                                         |
| ------------ | -------------------------------------------------------- | ------------------------------------------------ |
| `roundrobin` | Rotates through servers. Supports dynamic weight changes | General-purpose (default in <= 3.2)              |
| `static-rr`  | Like `roundrobin`, but ignores weight changes at runtime | Deterministic distribution                       |
| `leastconn`  | Picks the server with the fewest active connections      | Long-lived connections (SQL, gRPC, WebSocket)    |
| `source`     | Hashes client IP to select a server                      | Basic IP-based session persistence               |
| `uri`        | Hashes the request URI                                   | Caching proxies (same URI hits the same backend) |

Per-server weights control the traffic share that is forwarded to those specific servers:

```cfg
backend app_servers
    balance roundrobin
    server app1 192.168.1.10:8080 check weight 3
    server app2 192.168.1.11:8080 check weight 1
```

## Health checks

Adding `check` to a `server` line enables TCP health checks (connect and disconnect) for the servers belonging to that
backend.<br/>
For HTTP backends, `option httpchk` upgrades the check to send an actual HTTP request.

```cfg
backend app_servers
    option httpchk GET /health
    http-check expect status 200
    server app1 192.168.1.10:8080 check inter 5s fall 3 rise 2
    server app2 192.168.1.11:8080 check inter 5s fall 3 rise 2
```

`inter` is the interval between checks (defaults to 2s).<br/>
`fall` is the number of consecutive failures that need to happen before marking a server as down.
`rise` is the number of consecutive successes that need to happen before marking a down server as up again.

Checks can run on a different port than production traffic with `check port <port>`. There are protocol-specific checks
for MySQL (`option mysql-check`), PostgreSQL (`option pgsql-check`), and SMTP (`option smtpchk`).

## ACLs

Allow defining conditions based on request content.<br/>
They can be used for content-aware routing when combined with `use_backend`.

```cfg
frontend http_in
    bind *:80

    acl is_api path_beg /api/
    acl is_static path_end .css .js .png .jpg

    use_backend api_servers if is_api
    use_backend static_servers if is_static
    default_backend app_servers
```

Conditions support boolean logic (`or`, `!`), and can match on IP ranges, headers, cookies, URL patterns, and more.

## Stick tables

In-memory key-value stores that track per-client statistics (connection rates, request counts, bandwidth).<br/>
They enable session persistence and rate limiting.

```cfg
backend app_servers
    stick-table type ip size 100k expire 30m store http_req_rate(10s)
    http-request track-sc0 src
    http-request deny deny_status 429 if { sc_http_req_rate(0) gt 100 }

    balance roundrobin
    server app1 192.168.1.10:8080 check
    server app2 192.168.1.11:8080 check
```

The tables' contents can be inspected at runtime through the stats socket:

```sh
echo 'show table' | socat '/run/haproxy/admin.sock' -
echo 'show table app_servers' | socat '/run/haproxy/admin.sock' -
```

## Logging

HAProxy sends logs over UDP (or to a Unix socket) using the `syslog` format.<br/>
The `log` directive in the `global` configuration section sets the destination, while `option httplog` in a `frontend`
or `defaults` section enables detailed HTTP access logs.

```cfg
global
    log 127.0.0.1:514 local0 info

defaults
    log global
    option httplog
```

The `max log level` setting in the `log` directive (`info` in the example) controls which messages are emitted.<br/>
Setting it to `notice` suppresses `info`-level per-request HTTP access logs. In this case, it can look like the proxy is
not receiving traffic at all.

HAProxy 2.x added `option httpslog` to allow appending SSL/TLS fields (cipher, version, SNI) to the standard `httplog`
format without needing a custom `log-format` setting.

## Stats and runtime API

A `listen` section with `stats enable` exposes a web dashboard for live monitoring.

```cfg
listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:somePassword
```

The runtime API is a text-based interface that is exposed over a Unix socket.<br/>
It is configured via `stats socket` in the`global` section and allows live management without reloads:

```sh
# Show process info.
echo 'show info' | socat '/run/haproxy/admin.sock' -

# Show per-frontend/backend/server stats.
echo 'show stat' | socat '/run/haproxy/admin.sock' -

# Drain a server (stop new connections, finish existing ones).
echo 'set server app_servers/app1 state drain' | socat '/run/haproxy/admin.sock' -
```

Changes made through the runtime API are **not** persisted to the configuration file.

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
- [Starter guide]
- [Configuration tutorials]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/haproxytech
[configuration tutorials]: https://www.haproxy.com/documentation/haproxy-configuration-tutorials/
[documentation]: https://www.haproxy.com/documentation/
[starter guide]: https://docs.haproxy.org/3.2/intro.html
[website]: https://www.haproxy.com/

<!-- Others -->
