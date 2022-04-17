# The APT package manager

## TL;DR

```shell
# mark all packages as non-explicitly installed
apt-mark auto $(sudo apt-mark showmanual)

# remove orphaned packages
apt autoremove --purge
```

## Further readings

- [Apt configuration]
- [Configuring Apt sources]

[apt configuration]: https://wiki.debian.org/AptConfiguration
[configuring apt sources]: https://wiki.debian.org/SourcesList
