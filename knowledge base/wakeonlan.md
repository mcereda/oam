# wakeonlan

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install `wakeonlan`.
brew install 'wakeonlan'

# Broadcast a WOL package.
wakeonlan '11:22:33:44:55:66'

# Simulate the broadcast.
wakeonlan -n '11:22:33:44:55:66'

# Limit the magic package to specific networks or hosts.
# Use network *broadcast* addresses to ensure the magic packets can actually
# reach the target host; avoid this by having a static ARP table configured.
wakeonlan -i '192.168.1.255' '11:22:33:44:55:66'
wakeonlan -n '11:22:33:44:55:66' -i '192.168.100.3'
```

## Further readings

- [`man` page][man page]

## Sources

All the references in the [further readings] section, plus the following:

- [Wake a host from LAN]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[wake a host from lan]: wake%20a%20host%20from%20lan.md

<!-- Others -->
[man page]: https://www.unix.com/man-page/debian/1/WAKEONLAN/
