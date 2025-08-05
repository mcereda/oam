# Gitea

1. [TL;DR](#tldr)
1. [Installation](#installation)
1. [Configuration](#configuration)
   1. [LFS](#lfs)
   1. [HTTPS](#https)
      1. [HTTP redirection to HTTPS](#http-redirection-to-https)
   1. [Send emails](#send-emails)
   1. [Use Oauth2 for authentication](#use-oauth2-for-authentication)
      1. [Map OAuth2 users to Gitea teams and organizations](#map-oauth2-users-to-gitea-teams-and-organizations)
   1. [Search](#search)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install from source.
git clone 'https://github.com/go-gitea/gitea' -b 'release/v1.22' && cd 'gitea' \
&& TAGS='bindata sqlite sqlite_unlock_notify' make build

# Install as package.
apk add 'gitea'
brew install 'gitea'
emerge -aqv 'gitea'
pacman -S 'gitea'
pkg install 'gitea'

# Kubernetes
helm repo add 'gitea-charts' 'https://dl.gitea.com/charts/'
helm upgrade --install 'gitea' 'gitea-charts/gitea'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Start after installation from source.
./gitea web
```

</details>

## Installation

<details>
  <summary style="padding-bottom: 1rem">Container image</summary>

[Compose file example][compose file].

The `git` user has UID and GID set to `1000` by default.<br/>
Change those in the compose file or whatever one needs to.

One can optionally define the administrative user during the initial setup.<br/>
If no administrative user is defined in that moment, the **first registered user** becomes the administrator.

</details>

## Configuration

Refer the [Configuration cheat sheet].

Settings are loaded from the configuration file usually found at `/etc/gitea/app.ini`.

Container users can update the configuration file through environment variables.<br/>
The image runs `environment-to-ini` before running the server, which maps them to values in the ini file:

- Variables in the form `GITEA__{{SECTION_NAME}}__{{KEY_NAME}}` are mapped to the `[section_name]` ini section and the
  `KEY_NAME` key with the provided value.
- Variables in the form `GITEA__{{SECTION_NAME}}__{{KEY_NAME}}__{{PATH_TO_FILE}}` are mapped to the `[section_name]` ini
  section and the `KEY_NAME` key with the value loaded from the specified file.

Environment variables usually restricted to the `0-9A-Z_` reduced character.<br/>
To allow setting up sections with characters outside of that set, characters shall be escaped as a UTF8 byte string.
E.g. to configure:

```ini
[log.console]
COLORIZE = false
STDERR   = true
```

One would need to encode `.` as `_0X2E_` and set the environment variables `GITEA__LOG_0x2E_CONSOLE__COLORIZE=false` and
`GITEA__LOG_0x2E_CONSOLE__STDERR=false`.<br/>
Other examples can be found on the [configuration cheat sheet].

If using the helm chart with Kubernetes, the configuration settings defined in the values' `gitea.config` key are saved
in the `gitea-inline-config` secret and are then used to build the configuration file in the container.

### LFS

Enable the built-in LFS support:

```ini
[server]
LFS_START_SERVER = true

[lfs]
PATH = /home/gitea/data/lfs  # defaults to "{{data_directory}}/lfs"
```

### HTTPS

Refer [HTTPS setup to encrypt connections to Gitea].

If the certificate is signed by a third party certificate authority (i.e. not self-signed), then the  `cert.pem` file
shall contain the certificate chain too.<br/>
The server certificate must be **the first entry** in `cert.pem`, followed by the intermediaries in order (if any).<br/>
The root certificate does **not** need to be included, as the connecting client must already have it in order to
establish any trust relationship.

The file path in the configuration is relative to the `GITEA_CUSTOM` environment variable when it is a relative path.

<details style="padding-left: 1rem">
  <summary>Self-signed certificate</summary>

1. Generate a self signed certificate:

   ```sh
   gitea cert --host 'gitea.company.com'
   docker compose exec server gitea cert --host 'gitea.company.com'
   ```

1. Reference the certificate files in the configuration file:

   ```ini
   [server]
   PROTOCOL  = https
   ROOT_URL  = https://gitea.company.com:3000/
   HTTP_PORT = 3000
   CERT_FILE = /path/to/cert.pem
   KEY_FILE  = /path/to/key.pem
   ```

</details>

<details style="padding-left: 1em">
  <summary>ACME certificate</summary>

Defaults to using Let's Encrypt.

```ini
[server]
PROTOCOL       = https
DOMAIN         = gitea.company.com
ENABLE_ACME    = true
ACME_ACCEPTTOS = true
ACME_DIRECTORY = https
ACME_EMAIL     = user@company.com  # can be omitted here and provided manually at first run, after which it is cached
```

</details>

#### HTTP redirection to HTTPS

Gitea's server is able to listen on one port only and requires a separate service to provide redirection.<br/>
If HTTPS is enabled and one wants to offer an HTTP port to redirect HTTP requests from, enable the HTTP redirection
service:

```ini
[server]
REDIRECT_OTHER_PORT = true
PORT_TO_REDIRECT    = 3080  # http port that will be redirected to the https port
```

When using Docker, make sure this port is published too.

### Send emails

Use SMTP servers as relay should one want to leverage accounts at email providers.

<details>
  <summary>AWS</summary>

```ini
[mailer]
ENABLED   = true
PROTOCOL  = smtp+starttls
SMTP_ADDR = email-smtp.eu-west-1.amazonaws.com
SMTP_PORT = 587
USER      = AKIA…7890
PASSWD    = `ABCD…7890`
FROM      = noreply@gitea.company.com
```

</details>

<details>
  <summary style="padding-bottom: 1rem">Gmail</summary>

> Gmail will not allow the direct use of one's Google account password.<br/>
> Create an App password and enable 2FA on one's Google account.

```ini
[mailer]
ENABLED   = true
PROTOCOL  = smtps
SMTP_ADDR = smtp.gmail.com
SMTP_PORT = 465
FROM      = user@gmail.com
USER      = user
PASSWD    = `App_Password`
```

</details>

### Use Oauth2 for authentication

Remember to set up a mailer, should one want to require email confirmation during registration.

<details>
  <summary>Google Cloud example</summary>

1. Create a Client ID in [Google Cloud](https://console.cloud.google.com/apis/credentials) with at least the following
   settings:

   ```yaml
   Application type: web application
   Name: whatever  # anything is fine here
   Authorized JavaScript origins:
     - https://gitea.company.com:3000  # the ROOT_URL of one's instance
   Authorized redirect URIs:
     - # the 'Google' identifier here needs to be the name given to the provider in the next step
       https://gitea.company.com:3000/user/oauth2/Google/callback
   ```

1. Configure the provider in the Gitea instance at
   _Site Administration_ > _Identity & Access_ > _Authentication Sources_ with at least the following settings:

   ```yaml
   Authentication Type: OAuth2
   Authentication Name: Google  # this defines the identifier for the redirect URI above
   OAuth2 Provider: Google
   Client ID (Key): 012345678901-abcdefghijklmnopqrstuvwxyz012345.apps.googleusercontent.com
   Client Secret: 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
   ```

1. Configure the Gitea instance to automatically create users from the provider:

   ```ini
   [oauth2_client]
   ENABLE_AUTO_REGISTRATION: true
   USERNAME: email
   ```

</details>

#### Map OAuth2 users to Gitea teams and organizations

TODO

### Search

Users can do repository-level code search by default.

The builtin code search is based on the `git grep` command. It is fast and efficient for small repositories.<br/>
Better code search support could be achieved by setting up the repository indexer.

Refer [Repository indexer].

Indexing the repository's contents can consume lots of resources.<br/>
This is especially true when an index is created for the first time or globally updated (e.g. after upgrading Gitea).

```ini
[mailer]
REPO_INDEXER_ENABLED = true
```

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
- [Installation with Docker]
- [Installation with Helm]
- [Helm Chart]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[self-hosting]: self-hosting.md
[git]: git.md
[gitlab]: gitlab/README.md

<!-- Files -->
[compose file]: /docker%20compositions/gitea/docker-compose.yml

<!-- Upstream -->
[configuration cheat sheet]: https://docs.gitea.com/administration/config-cheat-sheet
[helm chart]: https://gitea.com/gitea/helm-chart/
[https setup to encrypt connections to gitea]: https://docs.gitea.com/administration/https-setup
[installation with docker]: https://docs.gitea.com/installation/install-with-docker-rootless
[installation with helm]: https://docs.gitea.com/installation/install-on-kubernetes
[repository indexer]: https://docs.gitea.com/administration/repo-indexer
[website]: https://about.gitea.com/
