# Netcat

- `-N`: close the network socket when finished; not available in nmap's netcat
- `-l`: bind to the port and listen for incoming connections (server mode)
- `-n`: do not resolve hostnames via DNS
- `-p`: specify the source port to use
- `-t`: use telnet negotiation
- `-u`: use UDP
- `-v`: set verbosity level; can be used several times
- `-w=SECS`: timeout for connects and final net reads, in seconds
- `-z`: zero-I/O mode, exit once connected

## TL;DR

```sh
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

# Listen mode.
nc -l 5666
```

## Sources

- [How To use Netcat to establish and test TCP and UDP connections]

<!-- project's references -->

[how to use netcat to establish and test tcp and udp connections]: https://www.digitalocean.com/community/tutorials/how-to-use-netcat-to-establish-and-test-tcp-and-udp-connections
