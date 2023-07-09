# `redis-cli`

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install it.
asdf plugin add 'redis-cli' && asdf install 'redis-cli' '6.2.12'
brew install 'redis'
dnf install 'redis'

# Connect to servers.
redis-cli -s 'socket'
redis-cli -h 'host.fqdn' -p 'port'
redis-cli … -a 'password'
REDISCLI_AUTH='password' redis-cli
redis-cli -u 'redis://username:password@host.fqdn:port/db_number'

# Execute commands.
redis-cli 'command' 'arg_1' … 'arg_N'
redis-cli -h 'localhost' 'PING'
redis-cli -n 'db_number' 'INCR' 'a'

# Execute commands from the master's container in kubernetes.
kubectl exec redis-0 -- redis-cli 'PING'

# Debug the server.
redis-cli … 'MONITOR'
```

## Further readings

- Redis' [website]
- Redis' [documentation]

## Sources

All the references in the [further readings] section, plus the following:

- [cheat.sh]

<!--
  References
  -->

<!-- Upstream -->
[documentation]: https://redis.io/docs/
[website]: https://redis.io/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- In-article sections -->
<!-- Others -->
[cheat.sh]: https://cheat.sh/redis-cli
