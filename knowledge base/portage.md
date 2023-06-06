# Portage

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

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
- [/etc/portage]

## Sources

All the references in the [further readings] section, plus the following:

<!-- project's references -->
[/etc/portage]: https://wiki.gentoo.org/wiki//etc/portage
[portage]: https://wiki.gentoo.org/wiki/Portage

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
<!-- external references -->
