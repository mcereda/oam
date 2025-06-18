# Certbot

Client that fetches a TLS certificate from [Let's Encrypt] and deploys it to a web server.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Meant to be run on one's web server via the CLI.

<details>
  <summary>Setup</summary>

```sh
pip install 'certbot'
pip install 'certbot-dns-cloudflare'  # leverage cloudflare
pip install 'certbot-dns-route53'  # leverage AWS Route53

# Integrate with Nginx.
dnf install 'certbot' 'nginx' 'python3-certbot-nginx'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Request a certificate.
docker run -it --rm --name 'certbot' \
  -v '/etc/letsencrypt:/etc/letsencrypt' -v '/var/lib/letsencrypt:/var/lib/letsencrypt' \
  'certbot/certbot' certonly

# Request a certificate and validate it over DNS leveraging AWS Route53.
docker run -it --rm --name 'certbot' \
  -v "$HOME/.aws:/root.aws:ro" \
  -v '/etc/letsencrypt:/etc/letsencrypt' -v '/var/lib/letsencrypt:/var/lib/letsencrypt' \
  'certbot/dns-route53' certonly

# Request a certificate.
# Certbot will temporarily spin up a web server listening on port 80 on the running machine.
certbot certonly --standalone

# Request a certificate *without* temporarily spin up a web server listening on port 80 on the running machine.
certbot certonly --webroot

# Request a certificate leveraging a running Nginx server.
certbot --nginx -d 'code.example.org' --non-interactive --agree-tos -m 'someone@example.org'

# Request a certificate leveraging AWS Route53.
certbot certonly --dns-route53 -d 'example.org' -d 'www.example.org'

# Request a certificate leveraging Cloudflare.
certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~'/.secrets/certbot/cloudflare.ini' \
  --dns-cloudflare-propagation-seconds 60 -d 'example.org'

# Renew certificates.
certbot renew -q
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

- [Website]
- [Codebase]
- [Let's Encrypt]
- [Nginx]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[let's encrypt]: letsencrypt.md
[nginx]: nginx.md

<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/certbot/certbot
[documentation]: https://certbot.eff.org/docs
[website]: https://certbot.eff.org/

<!-- Others -->
