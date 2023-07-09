# Portage

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# System update.
sudo emerge --sync
sudo emerge --depclean --ask
sudo emerge -qv --update --deep --newuse --with-bdeps=y -a @world

# Show what portage features are currently active.
portageq envvar 'FEATURES' | xargs -n1
```

## Further readings

- [Portage]
- [`/etc/portage`][/etc/portage]
- [Gentoo Linux]
- [Funtoo Linux]

<!--
  References
  -->

<!-- Upstream -->
[/etc/portage]: https://wiki.gentoo.org/wiki//etc/portage
[portage]: https://wiki.gentoo.org/wiki/Portage

<!-- Knowledge base -->
[gentoo linux]: gentoo%20linux.md
[funtoo linux]: funtoo%20linux.md
