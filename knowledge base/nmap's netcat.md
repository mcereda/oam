# Nmap's netcat

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Options of interest:

| Option              | Summary                                                                           |
| ------------------- | --------------------------------------------------------------------------------- |
| `-l`, `--listen`    | bind to the port given in input and listen for incoming connections (server mode) |
| `-k`, `--keep-open` | accept multiple connections in listen mode                                        |
| `-n`, `--nodns`     | do not resolve hostnames via DNS                                                  |
| `-p`                | specify the source port to use                                                    |
| `-t`                | use telnet negotiation                                                            |
| `-u`                | use UDP                                                                           |
| `-v`                | set verbosity level; can be used several times                                    |
| `-w=SECS`           | timeout for connects and final net reads, in seconds                              |
| `-z`                | zero-I/O mode, exit once connected                                                |

```sh
# Install
brew install 'nmap'
dnf install 'nmap-ncat'
yum install 'nmap-ncat'

# Check ports on hosts.
nc -Nnvz 192.168.0.81 22-25
nc -Nvz host.name 443
nc -Nvz -u dns.server 123

# List hosts with a specific port open.
# But you might just want to use `nmap`.
parallel -j 0 "nc -Nnvz -w 2 192.168.0.{} 22 2>&1" ::: {2..254} \
| grep -v "timed out"

# Wait for a host to be up.
until nc -Nvz -w 3 pi.lan 22; do sleep 3; done

# Server mode.
nc -l 5666
nc -lk 8080
```

## Further readings

### Sources

- [How To use Netcat to establish and test TCP and UDP connections]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Others -->
[how to use netcat to establish and test tcp and udp connections]: https://www.digitalocean.com/community/tutorials/how-to-use-netcat-to-establish-and-test-tcp-and-udp-connections
