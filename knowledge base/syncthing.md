# Syncthing

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Installation.
sudo apt install 'syncthing'
brew install --cask 'syncthing'
sudo zypper install 'syncthing'

# Startup.
syncthing
syncthing --gui-address '0.0.0.0:8384' --no-default-folder
systemctl --user start 'syncthing.service'
```

## Further readings

- [Website]

## Sources

All the references in the [further readings] section, plus the following:

- [The GUI listen address]
- [File versioning]

<!--
  References
  -->

<!-- Upstream -->
[file versioning]: https://docs.syncthing.net/users/versioning.html
[the gui listen address]: https://docs.syncthing.net/users/guilisten.html
[website]: https://syncthing.net/

<!-- In-article sections -->
[further readings]: #further-readings
