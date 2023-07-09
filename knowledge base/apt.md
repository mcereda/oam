# The APT package manager

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Automate security upgrades](#automate-security-upgrades)
1. [Configuration](#configuration)
1. [Version pinning](#version-pinning)
1. [Troubleshooting](#troubleshooting)
   1. [Fix a "Problem with MergeList" or "status file could not be parsed" error](#fix-a-problem-with-mergelist-or-status-file-could-not-be-parsed-error)
   1. [A package is not upgraded to the release and/or version I pinned](#a-package-is-not-upgraded-to-the-release-andor-version-i-pinned)
1. [Further readings](#further-readings)
1. [Sources](#sources)

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
sudo apt install 'nano' 'python3-zstd/stable' 'gparted=0.16.1-1'

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

# Check package priorities.
apt-check policy
apt-check policy 'boinc-client'

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

## Configuration

See [Apt configuration] for more information.

```txt
# /etc/apt/apt.conf.d/90default-release
APT::Default-Release "stable";
```

```txt
# /etc/apt/apt.conf.d/99parallel-fetch
APT::Acquire::Queue-Mode "access";
APT::Acquire::Retries 3;
```

## Version pinning

See [`apt_preferences`'s man page][apt_preferences man page] for more information.

```txt
# /etc/apt/preferences.d/99perl
Package: perl
Pin: version 5.20*
Pin-Priority: 1001
```

```txt
# /etc/apt/preferences.d/90debian-release
Package: *
Pin: release a=testing
Pin-Priority: 990
Package: *
Pin: release a=stable
Pin-Priority: 500
Package: *
Pin: release a=unstable
Pin-Priority: -1
```

```txt
# /etc/apt/preferences.d/boinc
Package: boinc boinc-client boinc-manager libboinc7
Pin: release a=unstable
Pin-Priority: 995
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

### A package is not upgraded to the release and/or version I pinned

1. The effective priority of the package might be lower than expected.<br/>
   Check the package's priority is the one you wanted **and** is higher than the release's one.

   ```sh
   $ apt-cache policy 'boinc-client'
   boinc-client:
   Installed: 7.16.16+dfsg-1
   Candidate: 7.20.5+dfsg-1.1
   Version table:
      7.20.5+dfsg-1.1 990     <-- wanted candidate, with its pinned priority
         490 http://deb.debian.org/debian testing/main arm64 Packages
          -1 http://deb.debian.org/debian unstable/main arm64 Packages
   *** 7.16.16+dfsg-1 500     <-- usable candidate, with its effective priority
         500 http://deb.debian.org/debian bullseye/main arm64 Packages
         100 /var/lib/dpkg/status
   ```

1. The package might depend on other packages which are not upgradable at the moment, i.e. their current version might be required by other packages.<br/>
   Try installing/upgrading it specifying the desired release and version of the package:

   ```sh
   $ sudo apt upgrade boinc-client/testing
   Reading package lists... Done
   Building dependency tree... Done
   Reading state information... Done
   Selected version '7.20.5+dfsg-1.1' (Debian:testing, Debian:unstable [arm64]) for 'boinc-client'
   Selected version '7.20.5+dfsg-1.1' (Debian:testing, Debian:unstable [arm64]) for 'libboinc7' because of 'boinc-client'
   Selected version '2.36-9' (Debian:testing, Debian:unstable [arm64]) for 'libc6' because of 'libboinc7'
   Selected version '3.0.8-1' (Debian:testing, Debian:unstable [arm64]) for 'libssl3' because of 'libboinc7'
   Selected version '12.2.0-14' (Debian:testing, Debian:unstable [arm64]) for 'libstdc++6' because of 'libboinc7'
   Calculating upgrade... Done
   Some packages could not be installed. This may mean that you have
   requested an impossible situation or if you are using the unstable
   distribution that some required packages have not yet been created
   or been moved out of Incoming.
   The following information may help to resolve the situation:

   The following packages have unmet dependencies:
    libc-bin : Depends: libc6 (< 2.32) but 2.36-9 is to be installed
    libc-dev-bin : Depends: libc6 (< 2.32) but 2.36-9 is to be installed
    libc6-dbg : Depends: libc6 (= 2.31-13+rpt2+rpi1+deb11u5) but 2.36-9 is to be installed
    libc6-dev : Depends: libc6 (= 2.31-13+rpt2+rpi1+deb11u5) but 2.36-9 is to be installed
   E: Broken packages
   ```

## Further readings

- [Apt configuration]
- [Configuring Apt sources]
- [Unattended Upgrades]
- [`apt_preferences`'s man page][apt_preferences man page]
- [`dpkg`][dpkg]
- [`apt-file`][apt-file] to look for files in packages
- [`netselect-apt`][netselect-apt] to select the fastest APT mirror

## Sources

All the references in the [further readings] section, plus the following:

- [cheat.sh]
- [Fix a "Problem with MergeList" or "status file could not be parsed" error]

<!-- upstream -->
[apt configuration]: https://wiki.debian.org/AptConfiguration
[apt_preferences man page]: https://manpages.debian.org/testing/apt/apt_preferences.5.en.html
[configuring apt sources]: https://wiki.debian.org/SourcesList
[unattended upgrades]: https://wiki.debian.org/UnattendedUpgrades

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
[apt-file]: apt-file.md
[dpkg]: dpkg.md
[netselect-apt]: netselect-apt.md

<!-- external references -->
[cheat.sh]: https://cheat.sh/apt
[fix a "problem with mergelist" or "status file could not be parsed" error]: https://askubuntu.com/questions/30072/how-do-i-fix-a-problem-with-mergelist-or-status-file-could-not-be-parsed-err#30199
