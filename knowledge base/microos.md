# OpenSUSE MicroOS

## TL;DR

Every set of changes to the underlying system is executed on a new inactive snapshot, which will be the one the system will boot into on the next reboot.

```sh
# Upgrade the system.
sudo transactional-update dup
pkcon update

# Install a package.
sudo transactional-update pkg install tlp ntfs-3g fuse-exfat nano
pkcon install gnu_parallel

# Get a shell on the next snapshot.
# Lets you use zypper.
sudo transactional-update shell
sudo tukit execute bash
```

## Setting up MicroOS as a desktop OS

See [MicroOS Desktop] for more and updated information.

## Further readings

- [Flatpak]
- [Toolbox]

[flatpak]: flatpak.md
[toolbox]: toolbox.md

## Sources

- [MicroOS Desktop]
- [MicroOS Portal]

[microos desktop]: https://opensuse.github.io/openSUSE-docs-revamped-temp/microos_getting_started/
[microos portal]: https://en.opensuse.org/Portal:MicroOS
