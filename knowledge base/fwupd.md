# Fwupd

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Installation.
apt install 'fwupd'
emerge -aqv 'sys-apps/fwupd'
pacman -Sy 'fwupd'
pamac install 'fwupd'
yum install 'fwupd'
zypper install 'fwupd'
```

</details>

<details>
  <summary>Usage</summary>

```sh

# Display detected devices.
fwupdmgr get-devices
fwupdmgr get-devices --show-all-devices

# Download the latest metadata from LVFS.
fwupdmgr refresh
fwupdmgr refresh --force

# Display available updates, if present.
fwupdmgr get-updates

# Download and apply available updates.
fwupdmgr update
fwupdmgr update -v 'f95c9218acd12697af946874bfe4239587209232'

# Report the status of an update.
fwupdmgr report-history

# Clear the local history of updates.
fwupdmgr clear-history
```

</details>

## Further readings

- [Website]
- [GitHub] page
- [Supported devices]

## Sources

- [Arch wiki]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[github]: https://github.com/fwupd/fwupd
[supported devices]: https://fwupd.org/lvfs/devices/
[website]: https://fwupd.org/

<!-- Others -->
[arch wiki]: https://wiki.archlinux.org/title/fwupd
