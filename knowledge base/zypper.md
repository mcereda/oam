# The Zypper package manager

SUSE and openSUSE GNU/Linux's package management utility and command-line interface to the ZYpp system management library (`libzypp`).

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Concepts](#concepts)
1. [Gotchas](#gotchas)
1. [Further readings](#further-readings)

## TL;DR

Default files:

| Path                       | Description                                                 |
| -------------------------- | ----------------------------------------------------------- |
| `${HOME}/.zypper.conf`     | User configuration file for Zypper                          |
| `/etc/zypp/zypper.conf`    | Global configuration file for Zypper                        |
| `/etc/zypp/zypp.conf`      | Configuration file for `libzypp`                            |
| `/etc/zypp/locks`          | Package lock definitions                                    |
| `/etc/zypp/repos.d`        | Directory containing repository definition files (`*.repo`) |
| `/etc/zypp/services.d`     | Directory containing service definition files (`*.service`) |
| `/usr/lib/zypp/commands`   | Directory for zypper extensions                             |
| `/var/cache/zypp/raw`      | Cache directory for downloaded, raw package metadata        |
| `/var/cache/zypp/solv`     | Cache directory for pre-parsed package metadata (`*.solv`)  |
| `/var/cache/zypp/RPMS`     | Cache directory for downloaded packages                     |
| `/var/cache/zypp/packages` | Cache directory for installed packages                      |
| `/var/log/zypper.log`      | Zypper's log file                                           |
| `/var/log/zypp/history`    | Installation history log file                               |

Command examples:

```sh
# Update the package cache.
zypper refresh
zypper ref 'updates'

# Search for resolvables.
zypper search 'nmap'
zypper se 'mariadb'

# Display detailed information about resolvables.
zypper info 'workrave'
zypper if -t 'patch' 'libzypp'
zypper if -t 'pattern' 'lamp_server'

# Install resolvables.
zypper install 'parallel'
zypper in --no-confirm 'https://prerelease.keybase.io/keybase_amd64.rpm'
zypper in --no-recommends 'gv' 'virtualbox-ose=2.0.6' '/root/ansible.rpm'

# Install resolvables from source.
# The source packages *must* be available in the repositories one is using.
zypper source-install -d 'dbus-1'
zypper si 'dolphin-plugins'

# Check the dependencies of *installed* packages are satisfied.
zypper verify 'git-lfs'
zypper ve 'virtualbox'

# Uninstall resolvables.
zypper remove 'code'
zypper rm 'zfs'
zypper in '!Firefox' '-htop'

# List available updates.
# By default, it shows only *installable* ones.
zypper list-updates
zypper lu --all

# Update installed packages.
zypper update
zypper up 'vivaldi-stable'

# List available patches.
# By default, it shows only *applicable* ones.
zypper list-patches
zypper lp --all

# Check whether there are applicable patches.
zypper patch-check
zypper pchk --with-optional

# Apply patches.
zypper patch

# Perform a distribution upgrade.
zypper dist-upgrade
zypper dup --details --from 'factory' --from 'packman'


# List currently defined repositories.
zypper repos
zypper rl -d

# Add repositories.
zypper addrepo --check --refresh --priority '90' \
  'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/' \
  'packman'
zypper ar …

# Remove repositories.
zypper removerepo 'mozilla'
zypper rr '3'

# Rename repositories.
zypper renamerepo 'firefox' 'mozilla'
zypper nr '5' 'packman'

# Modify repositories.
zypper modifyrepo -er 'updates'
zypper mr -da


# Clean caches.
zypper clean --metadata
zypper clean --all 'packman'

# Execute without user confirmation (non-interactively).
zypper --non-interactive …

# Clean up installed kernel packages.
zypper purge-kernels --dry-run
```

## Concepts

The set of packages installed on a system is denoted as the _@System_ repository or _System Packages_.<br/>
In contrast to normal repositories, @System provides packages that can only be deleted.

Installed packages which do not belong to any available repository are denoted as _unwanted_, _orphaned_ or _dropped_.

One can specify the location of packages or repositories using any type of URI supported by `libzypp` (e.g. local paths, ftp/https/other URI).<br/>
In addition, Zypper accepts openSUSE Build Service repositories in the `addrepo` command in the form of `obs://project/platform` URI.

Resource objects are called _resolvables_.<br/>
They might be **packages**, **patches**, **patterns**, **products**, or basically any kind of object with dependencies to other objects managed by `libzypp`.

If one does not request specific versions of resolvables during an action, Zypper's dependency solver will pick a _reasonable_ one automatically.

## Gotchas

Global options **must** be specified **before** the command name.<br/>
Command-specific options **must** be specified **after** the command name.

Zypper does not have for now a way to list **the content** of an **installed** package. Use [rpm] for this:

```sh
sudo rpm --query --list 'parallel'
```

## Further readings

- [rpm]
- [How can I list all files which have been installed by an ZYpp/Zypper package?]

<!--
  References
  -->

<!-- Knowledge base -->
[rpm]: rpm.md

<!-- Others -->
[how can i list all files which have been installed by an zypp/zypper package?]: https://unix.stackexchange.com/questions/162092/how-can-i-list-all-files-which-have-been-installed-by-an-zypp-zypper-package#239944
