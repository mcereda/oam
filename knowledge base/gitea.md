# Gitea

1. [Installation](#installation)
1. [Configuration](#configuration)
   1. [LFS](#lfs)
   1. [HTTPS certificates](#https-certificates)
   1. [Set up HTTP redirection](#set-up-http-redirection)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Installation

Docker [compose file].

The `git` user has UID and GID set to 1000 by default.<br/>
Change those in the compose file or whatever.

One can optionally define the administrative user during the initial setup.<br/>
If no administrative user is defined in that moment, the first registered user becomes the administrator.

## Configuration

Refer the [Configuration cheat sheet].

### LFS

Enable the built-in LFS support by updating the `app.ini` configuration file:

```ini
[server]
LFS_START_SERVER = true

[lfs]
PATH = /home/gitea/data/lfs  # defaults to {{data}}/lfs
```

### HTTPS certificates

Refer [HTTPS setup to encrypt connections to Gitea].

If the certificate is signed by a third party certificate authority (i.e. not self-signed), then `cert.pem` should
contain the certificate chain.<br/>
The server certificate must be **the first entry** in `cert.pem`, followed by the intermediaries in order (if any).<br/>
The root certificate does **not** have to be included as the connecting client must already have it in order to
establish any trust relationship.

The file path in the configuration is relative to the `GITEA_CUSTOM` environment variable when it is a relative path.

<details>
  <summary>Self-signed certificate</summary>

1. Generate a self signed certificate:

   ```sh
   gitea cert --host 'git.host.fqdn'
   docker compose exec server gitea cert --host 'git.host.fqdn'
   ```

1. Change the `app.ini` configuration file:

   ```ini
   [server]
   PROTOCOL  = https
   ROOT_URL  = https://git.host.fqdn:3000/
   HTTP_PORT = 3000
   CERT_FILE = /path/to/cert.pem
   KEY_FILE  = /path/to/key.pem
   ```

</details>
<details>
  <summary>ACME certificate</summary>

Defaults to using Let's Encrypt.

Change the `app.ini` configuration file:

```ini
[server]
PROTOCOL=https
DOMAIN=git.example.com
ENABLE_ACME=true
ACME_ACCEPTTOS=true
ACME_DIRECTORY=https
ACME_EMAIL=email@example.com  # can be omitted here and provided manually at first run, after which it is cached
```

</details>

### Set up HTTP redirection

Gitea server is able to listen on one single port. Enable the HTTP redirection service to redirect HTTP requests to the
HTTPS port:

```ini
[server]
REDIRECT_OTHER_PORT = true
PORT_TO_REDIRECT = 3080  # http port to be redirected to https
```

When using Docker, make sure this port is published.

## Further readings

- [Self-hosting]
- [Website]
- [Compose file]
- [Git]

Alternatives:

- [Gitlab]

### Sources

- [Configuration cheat sheet]
- [HTTPS setup to encrypt connections to Gitea]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[self-hosting]: self-hosting.md
[git]: git.md
[gitlab]: gitlab.md

<!-- Files -->
[compose file]: /docker/gitea/docker-compose.yml

<!-- Upstream -->
[configuration cheat sheet]: https://docs.gitea.com/administration/config-cheat-sheet
[https setup to encrypt connections to gitea]: https://docs.gitea.com/administration/https-setup
[website]: https://about.gitea.com/
