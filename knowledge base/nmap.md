# Nmap

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# scan all 65535 ports on a host
nmap -p- 192.168.1.1

# scan a single port on a subnet
nmap -p 22 192.168.0.0/24

# detect a host's os
nmap -O 192.168.0.1
```

## Further readings

- [Cheatsheet]
- [OS detection]

<!--
  References
  -->

<!-- Upstream -->
[os detection]: https://nmap.org/book/man-os-detection.html


<!-- Others -->
[cheatsheet]: https://hackertarget.com/nmap-cheatsheet-a-quick-reference-guide/
