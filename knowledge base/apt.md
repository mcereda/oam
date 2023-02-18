# The APT package manager

## TL;DR

```sh
# Check for broken dependencies.
sudo apt-get check

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
sudo dpkg-reconfigure -p 'low' 'unattended-upgrades'
```

## Automate security upgrades

Leverage `unattended-upgrades` for this.

```sh
# Configure the packages to keep up to date.
sudo dpkg-reconfigure -p 'low' 'unattended-upgrades'

# Check what packages would be installed.
sudo unattended-upgrade -d --dry-run

# Run manually.
sudo unattended-upgrade
```

## Troubleshooting

### Fix a "Problem with MergeList" or "status file could not be parsed" error

> E: Encountered a section with no Package: header
> E: Problem with MergeList /var/lib/apt/lists/deb.debian.org_debian_dists_bullseye_main_i18n_Translation-en
> E: The package lists or status file could not be parsed or opened.

```sh
sudo rm -vrf '/var/lib/apt/lists/'*
sudo apt update
```

## Further readings

- [Apt configuration]
- [Configuring Apt sources]
- [Unattended Upgrades]
- [cheat.sh]

## Sources

- [Fix a "Problem with MergeList" or "status file could not be parsed" error]

<!-- external references -->
[apt configuration]: https://wiki.debian.org/AptConfiguration
[configuring apt sources]: https://wiki.debian.org/SourcesList
[unattended upgrades]: https://wiki.debian.org/UnattendedUpgrades
[cheat.sh]: https://cheat.sh/apt
[fix a "problem with mergelist" or "status file could not be parsed" error]: https://askubuntu.com/questions/30072/how-do-i-fix-a-problem-with-mergelist-or-status-file-could-not-be-parsed-err#30199
