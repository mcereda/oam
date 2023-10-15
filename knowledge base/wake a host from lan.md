# Wake a host from LAN

The host needs to support wake-on-LAN and have it enabled.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

See [`wakeonlan`][wakeonlan] or [`wol`][wol].

```sh
# Check the magic packet arrives on the target machine.
sudo tcpdump -nXxei any ether proto 0x0842 or udp port 9
```

## Further readings

- [`wakeonlan`][wakeonlan]
- [`wol`][wol]

## Sources

All the references in the [further readings] section, plus the following:

- [How to wake up computers using Linux by sending magic packets]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[wakeonlan]: wakeonlan.md

<!-- Others -->
[how to wake up computers using linux by sending magic packets]: https://www.cyberciti.biz/tips/linux-send-wake-on-lan-wol-magic-packets.html
[wol]: https://sourceforge.net/projects/wake-on-lan/
