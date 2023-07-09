# wakeonlan

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install `wakeonlan`.
brew install 'wakeonlan'

# Send a WOL package to the host.
wakeonlan '11:22:33:44:55:66'

# Simulate.
wakeonlan -n '11:22:33:44:55:66'

# Limit the magic package to a specific network or host.
# Use a network's *broadcast* address unless you have a static ARP table
# configured so the magic packet can actually reach the single host.
wakeonlan -i '192.168.1.255' '11:22:33:44:55:66'
wakeonlan -n '11:22:33:44:55:66' -i '192.168.100.3'
```

## Further readings

- [`man` page][man page]

## Sources

All the references in the [further readings] section, plus the following:

- [wake a host from lan]

<!-- upstream -->
<!-- internal references -->

[further readings]: #further-readings

[wake a host from lan]: wake%20a%20host%20from%20lan.md

<!-- external references -->

[man page]: https://www.unix.com/man-page/debian/1/WAKEONLAN/
