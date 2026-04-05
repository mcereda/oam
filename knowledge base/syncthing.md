# Syncthing

Synchronizes files continuously between two or more computers.

1. [TL;DR](#tldr)
1. [Ignore files](#ignore-files)
1. [Troubleshooting](#troubleshooting)
   1. [I forgot the password](#i-forgot-the-password)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

Configuration files:

| OS      | Path                                                           |
| ------- | -------------------------------------------------------------- |
| Linux   | `$XDG_STATE_HOME/syncthing`<br/>`$HOME/.local/state/syncthing` |
| macOS   | `$HOME/Library/Application Support/Syncthing`                  |
| Windows | `%LOCALAPPDATA%\Syncthing`                                     |

```sh
# Installation.
sudo apt install 'syncthing'
brew install --cask 'syncthing'
sudo zypper install 'syncthing'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Startup.
syncthing
syncthing --gui-address '0.0.0.0:8384' --no-default-folder
systemctl --user start 'syncthing.service'
```

</details>

## Ignore files

Refer to [Documentation / Ignoring Files].

## Troubleshooting

### I forgot the password

Remove the entry under `gui.password` in the [configuration file][documentation / syncthing configuration]:

```sh
# With XMLStarlet
xml ed -L -d 'configuration/gui/password' 'Library/Application Support/Syncthing/config.xml'
```

Then enter the settings on the host and set a new password.

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/syncthing/syncthing
[Documentation / Ignoring Files]: https://docs.syncthing.net/users/ignoring
[Documentation / Syncthing Configuration]: https://docs.syncthing.net/users/config.html
[Documentation]: https://docs.syncthing.net
[Website]: https://syncthing.net/

<!-- Others -->
