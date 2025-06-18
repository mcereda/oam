# Nginx

TODO

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
dnf install 'nginx'

vim '/etc/nginx/conf.d/some-web-service.conf'
```

```conf
# Redirect traffic on port 80 to port 443.
server {
    listen 80;
    server_name some-web-service.example.org;

    location / {
        return 301 https://$host$request_uri;
    }
}

# Proxy incoming traffic.
server {
    listen       443  ssl;
    server_name  some-web-service.example.org;

    ssl_certificate      /etc/ssl/certs/some-web-service.example.org.crt;
    ssl_certificate_key  /etc/ssl/private/some-web-service.example.org.key;

    # Optional
    ssl_protocols  TLSv1.2 TLSv1.3;
    ssl_ciphers    HIGH:!aNULL:!MD5;

    location / {
        proxy_pass https://some-destination.example.org;
        proxy_set_header Host some-destination.example.org;

        # Optional but recommended
        proxy_set_header  X-Real-IP          $remote_addr;
        proxy_set_header  X-Forwarded-For    $proxy_add_x_forwarded_for;
        proxy_set_header  X-Forwarded-Proto  https;

        # Only when the destination uses self-signed certs
        proxy_ssl_verify  off;
    }
}
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Check the whole configuration and exit.
nginx -t
# Check the whole configuration, dump it, and exit.
nginx -T

# Start the server.
nginx
systemctl start 'nginx.service'

# Reload the configuration files.
nginx -s 'reload'
kill -s 'HUP' '1628'
pkill -HUP 'nginx'

# Reopen the log files.
nginx -s 'reopen'
kill -s 'USR1' '1628'
pkill -USR1 'nginx'

# Gracefully shutdown the server.
nginx -s 'quit'
kill -s 'QUIT' '1628'
pkill -QUIT 'nginx'
# Quickly shutdown the server.
nginx -s 'stop'
kill -s 'INT' '1628'
pkill -TERM 'nginx'
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

- [Proxy]
- [Website]
- [Nginx Proxy Manager]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[nginx proxy manager]: nginx%20proxy%20manager.md
[proxy]: proxy.md

<!-- Files -->
<!-- Upstream -->
[documentation]: https://nginx.org/en/docs/
[website]: https://nginx.org/en/

<!-- Others -->
