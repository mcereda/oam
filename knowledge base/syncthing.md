# Syncthing

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Troubleshooting](#troubleshooting)
   1. [I forgot the password](#i-forgot-the-password)
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

## Configuration

| OS       | Path                                                           |
| -------- | -------------------------------------------------------------- |
| Linux    | `$XDG_STATE_HOME/syncthing`<br/>`$HOME/.local/state/syncthing` |
| Mac OS X | `$HOME/Library/Application Support/Syncthing`                  |
| Windows  | `%LOCALAPPDATA%\Syncthing`                                     |

## Troubleshooting

### I forgot the password

Remove the entry under `gui.password` in the [configuration file][configuration]:

```sh
# With XMLStarlet
xml ed -L -d 'configuration/gui/password' 'Library/Application Support/Syncthing/config.xml'
```

Then enter the settings on the host and set a new password.

## Further readings

- [Website]

### Sources

- [The GUI listen address]
- [File versioning]
- [Configuration]

<!--
  References
  -->

<!-- In-article sections -->
[configuration]: #configuration

<!-- Upstream -->
[configuration]: https://docs.syncthing.net/users/config.html
[file versioning]: https://docs.syncthing.net/users/versioning.html
[the gui listen address]: https://docs.syncthing.net/users/guilisten.html
[website]: https://syncthing.net/

<!-- In-article sections -->
[further readings]: #further-readings
