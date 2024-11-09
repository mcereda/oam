# NATS

Messaging system.

1. [TL;DR](#tldr)
1. [Troubleshooting](#troubleshooting)
   1. [Context deadline exceeded](#context-deadline-exceeded)
   1. [No responders available for request](#no-responders-available-for-request)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

  <details style="padding: 0 0 0 1em">
    <summary>Server</summary>

```sh
# Install.
brew install 'nats-server'
choco install 'nats-server'
docker pull 'nats'
go install 'github.com/nats-io/nats-server/v2@latest'
yay 'nats-server'

# Validate the configuration file.
nats-server -c '/etc/nats/nats-server.conf' -t
docker run --rm --name 'pg_flo_nats' -v "$PWD/config/nats-server.conf:/etc/nats/nats-server.conf" 'nats' \
  -c '/etc/nats/nats-server.conf' -t
```

  </details>

  <details style="padding: 0 0 0 1em">
    <summary>Client</summary>

```sh
# Install.
brew install 'nats-io/nats-tools/nats'
```

  </details>

</details>

<details>
  <summary>Usage</summary>

  <details style="padding: 0 0 0 1em">
    <summary>Server</summary>

```sh
# Get help.
docker run --rm --name 'pg_flo_nats' 'nats' --help

# Run.
nats-server -V
nats-server -config 'nats-server.conf'
docker run --name 'nats' -p '4222:4222' -ti 'nats:latest' -js

# Run as cluster.
docker run --name 'nats-0' --network 'nats' -p '4222:4222' -p '8222:8222' \
  'nats' --http_port '8222' --cluster_name 'NATS' --cluster 'nats://0.0.0.0:6222' \
&& docker run --name 'nats-1' --network 'nats' \
  'nats' --cluster_name 'NATS' --cluster 'nats://0.0.0.0:6222' --routes='nats://ruser:T0pS3cr3t@nats:6222' \
&& curl -fs 'http://localhost:8222/routez'

# Reload the configuration.
nats-server --signal 'reload'
```

  </details>

  <details style="padding: 0 0 0 1em">
    <summary>Client</summary>

```sh
# Get help.
nats cheat server

# Check connection to the server.
nats server check connection --server 'nats://0.0.0.0:4222'
nats server check connection -s 'nats://localhost:4222'

# Request a configuration reload.
nats --user 'sys' --password 'sys' request '$SYS.REQ.SERVER.<server-id>.RELOAD' ""

# Start subscribers.
nats subscribe '>' -s '0.0.0.0:4222'
nats subscribe -s 'nats://demo.nats.io' '>'

# Publish messages.
nats pub 'hello' 'world' -s '0.0.0.0:4222'

# Start listeners for Request-Reply patterns.
nats reply 'subject' 'message'

# Send requests for Request-Reply patterns.
nats request 'help.please' 'I need help!'

# List configuration contexts
nats context ls
nats context ls --all

# List available JetStream streams.
nats stream ls
nats stream ls --all

# List available JetStream consumer.
nats consumer ls
nats consumer ls --all
```

  </details>

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Try out the Request-Reply pattern.
# The listener will hang waiting, run the second in another shell session.
nats reply 'help.please' 'OK, I CAN HELP!!!'
nats request 'help.please' 'I need help!'
```

</details>

## Troubleshooting

### Context deadline exceeded

Error message example:

```plaintext
FTL Failed to create NATS client error="failed to create main stream: context deadline exceeded"
```

Root cause: the client cannot reach the server.

### No responders available for request

Error message example:

```plaintext
FTL Failed to create NATS client error="failed to create main stream: nats: no responders available for request"
```

Root cause: a request is sent to a subject that has no subscribers.

## Further readings

- [Website]
- [Codebase]
- [Documentation]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/nats-io
[documentation]: https://docs.nats.io
[website]: https://nats.io/

<!-- Others -->
