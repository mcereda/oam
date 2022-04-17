# Portage

```shell
# system update
sudo emerge --sync
sudo emerge --quiet --verbose --update --deep --newuse --with-bdeps=y --ask @world
sudo emerge --depclean --ask

# check active portage features
portageq envvar FEATURES | xargs -n 1
```

## Further readings

- [/etc/portage]
- [Portage]

[/etc/portage]: https://wiki.gentoo.org/wiki//etc/portage
[portage]: https://wiki.gentoo.org/wiki/Portage
