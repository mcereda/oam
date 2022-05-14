# Portage

## TL;DR

```sh
# System update.
sudo emerge --sync
sudo emerge --depclean --ask
sudo emerge -qv --update --deep --newuse --with-bdeps=y -a @world

# Show what portage features are currently active.
portageq envvar FEATURES | xargs -n1
```

## Sources

- [/etc/portage]
- [Portage]

[/etc/portage]: https://wiki.gentoo.org/wiki//etc/portage
[portage]: https://wiki.gentoo.org/wiki/Portage
