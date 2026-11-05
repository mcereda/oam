# Syncthing

Synchronizes files continuously between two or more computers.

1. [TL;DR](#tldr)
1. [Ignore files](#ignore-files)
1. [Troubleshooting](#troubleshooting)
   1. [I forgot the password](#i-forgot-the-password)
   1. [Some files keep being renamed with the `.tmp` extension](#some-files-keep-being-renamed-with-the-tmp-extension)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

> [!caution] Documented issues with Unicode normalization.
> Linux and Windows use decomposition (NFD) when encoding characters in Unicode, but macOS uses composition (NFC) by
> default. E.g., `Ü` can be represented as `U` + `umlaut` (`U+0055` + `U+0308`, NFD) or as `Ü` (`U+00DC`, NFC).\
> Syncthing tries to convert the encoding to the one used by the hosts, which _could_ end up in a loop involving that
> file being renamed with the `.tmp` extension while syncing up continuously.
>
> See [autoNormalize], [File names, unicode normalization problems, and how to fix them] and
> [Syncthing should offer fixing UTF-8 encoding issues/conflicts].

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
brew install --cask 'syncthing'
sudo apt install 'syncthing'
sudo zypper install 'syncthing'
```

</details>

| Port/Protocol | Summary                                                        |
| ------------- | -------------------------------------------------------------- |
| 8384/TCP      | Default web UI port                                            |
| 22000/TCP     | Data transfer and Sync protocol's traffic via TCP              |
| 22000/UDP     | Data transfer Sync protocol's traffic via QUIC                 |
| 21027/UDP     | Local network discovery (broadcast on IPv4, multicast on IPv6) |
| 22067/UDP     | Data transfer via relay protocol fallback (`strelaysrv`)       |

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

### Some files keep being renamed with the `.tmp` extension

The file's name most probably contains a Unicode character that is encoded differently on another host.\
See the caution call box in the [TL;DR].

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]
- [Syncthing Port Guide: Fast Setup & Direct P2P Sync Fix]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[TL;DR]: #tldr

<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[autoNormalize]: https://docs.syncthing.net/advanced/folder-autonormalize.html
[Codebase]: https://github.com/syncthing/syncthing
[Documentation / Ignoring Files]: https://docs.syncthing.net/users/ignoring
[Documentation / Syncthing Configuration]: https://docs.syncthing.net/users/config.html
[Documentation]: https://docs.syncthing.net
[Website]: https://syncthing.net/

<!-- Others -->
[File names, unicode normalization problems, and how to fix them]: https://nicolasbouliane.com/blog/unicode-normalization
[Syncthing Port Guide: Fast Setup & Direct P2P Sync Fix]: https://natchecker.com/blog/syncthing-port
[Syncthing should offer fixing UTF-8 encoding issues/conflicts]: https://github.com/syncthing/syncthing/issues/430
