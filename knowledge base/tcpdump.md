# tcpdump

## TL;DR

```sh
# Get all packets in and out of an interface.
tcpdump -i 'eth0'

# Get all packets to or from a host.
tcpdump host '1.1.1.1'

# Get all packets from a source or for a destination.
tcpdump src '1.1.1.1'
tcpdump dst '1.0.0.1'

# Get all packets to or from a network.
tcpdump net '1.2.3.0/24'

# Get packets to or from ports.
tcpdump port '3389'
tcpdump portrange '21-23'

# Get packets of a protocol.
tcpdump icmp

# Get packages based on their size.
tcpdump less '32'
tcpdump greater '64'
tcpdump <= '128'

# Combine filters.
tcpdump src port '1025'
tcpdump -nnvvS src '10.5.2.3' and dst port '3389'
tcpdump -nX src net '192.168.0.0/16' and dst net '10.0.0.0/8' or '172.16.0.0/16'
tcpdump dst '192.168.0.2' and src net and not icmp
tcpdump -vv src 'mars' and not dst port '22'
tcpdump 'src 10.0.2.4 and (dst port 3389 or 22)'

# Save results to a file.
tcpdump port '80' -w 'path/to/capture.file'

# Read packets from a file.
tcpdump -r 'path/to/capture.file'

# Isolate TCP flags.
tcpdump 'tcp[tcpflags] == tcp-fin'
```

## Sources

- [A tcpdump tutorial with examples — 50 ways to isolate traffic]

<!-- upstream -->
<!-- internal references -->
<!-- external references -->
[a tcpdump tutorial with examples — 50 ways to isolate traffic]: https://danielmiessler.com/study/tcpdump/
