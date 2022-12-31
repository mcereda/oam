# The APT package manager

## TL;DR

```sh
# Update the packages lists.
sudo apt update

# Upgrade the system.
sudo apt upgrade
sudo apt dist-upgrade

# Look for packages.
apt search 'ansible'
apt search --names-only 'python'

# Show details of packages.
apt show 'vlc'

# List a package's dependencies.
apt depends 'ufw'

# Install packages.
sudo apt install 'nano' 'python3-zstd/stable'

# Remove packages.
sudo apt remove 'dhclient' 'sudo'
sudo apt remove --purge 'bluez'
sudo apt purge 'crda'

# Remove orphaned packages.
sudo apt autoremove --purge

# List packages.
sudo apt list
sudo apt list --upgradable
sudo apt list --installed

# List explicitly installed packages only.
sudo apt-mark showmanual

# Mark packages as explicitly installed.
sudo apt-mark manual 'vim' 'unattended-upgrades'

# List non-explicitly installed packages only.
sudo apt-mark showauto

# Mark packages as non-explicitly installed.
sudo apt-mark auto 'zsh' 'bash-completion'
sudo apt-mark auto $(sudo apt-mark showmanual)

# Reconfigure packages.
sudo dpkg-reconfigure 'mariadb-server'
```

## Automate security upgrades

Leverage `unattended-upgrades` for this.

```sh
# Check what packages would be installed.
sudo unattended-upgrade -d --dry-run

# Run manually.
sudo unattended-upgrade
```

## Further readings

- [Apt configuration]
- [Configuring Apt sources]
- [Unattended Upgrades]
- [cheat.sh]

<!-- external references -->
[apt configuration]: https://wiki.debian.org/AptConfiguration
[configuring apt sources]: https://wiki.debian.org/SourcesList
[unattended upgrades]: https://wiki.debian.org/UnattendedUpgrades
[cheat.sh]:
