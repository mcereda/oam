# The Zypper package manager

SUSE and openSUSE GNU/Linux's package management utility and command-line interface to the ZYpp system management
library (`libzypp`).

1. [TL;DR](#tldr)
1. [Concepts](#concepts)
1. [Repositories](#repositories)
1. [Configuration](#configuration)
1. [Gotchas](#gotchas)
1. [Distribution's release upgrade](#distributions-release-upgrade)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

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

Mark packages as **automatically** installed by adding them to `/var/lib/zypp/AutoInstalled`.<br/>
Mark packages as **manually** installed by removing them from that file or forcefully reinstalling them
(`zypper in -f 'tmux'`).

Command examples:

```sh
zypper help
zypper help 'command'

# ---

# Update caches.
zypper refresh
zypper ref --force 'updates' 'mozilla'

# Clean caches.
zypper clean --metadata
zypper clean --all 'packman'

# Clean up locks.
zypper cleanlocks

# ---

# Search for resolvables.
zypper search 'nmap'
zypper se -r 'repository' 'mariadb'
zypper se --type 'pattern' 'kde_plasma'

# List all patterns.
zypper se -t 'pattern'
zypper se -n 'patterns-*'

# Show all available versions of resolvables.
zypper se -s 'kernel-default'
zypper se --details 'boinc-client'

# Look up what package provides a file.
# 'what-provides' has been replaced by 'search -x --provides'
zypper se --provides '/usr/sbin/useradd'

# Display detailed information about resolvables.
zypper info 'workrave'
zypper if --type 'patch' 'libzypp'
zypper if -t 'pattern' 'lamp_server'

# Install resolvables.
zypper install -n 'parallel'
zypper in --no-confirm 'https://prerelease.keybase.io/keybase_amd64.rpm'
zypper in --no-recommends 'yast*ftp*' 'virtualbox-ose=2.0.6' '/root/ansible.rpm'

# Install from specific repositories.
# Requires the repo to be already added.
zypper in 'packman:libavdevice60'
zypper in -r 'packman' --download 'in-advance' 'libavdevice60'
zypper in -r 'https://repo.vivaldi.com/archive/vivaldi-suse.repo' 'vivaldi'

# Reinstall resolvables.
# This marks them as *manually* installed.
zypper in -f 'amdgpu-dkms'

# Install resolvables from source.
# The source packages *must* be available in the repositories one is using.
zypper source-install -d 'dbus-1'
zypper si 'dolphin-plugins'

# Check the dependencies of *installed* resolvables are satisfied.
zypper verify
zypper ve 'virtualbox' 'git-lfs'

# Uninstall resolvables.
zypper remove --clean-deps 'code'
zypper rm -u 'libreoffice' 'patterns-kde-kde_games'
zypper rm -ut 'pattern' 'games'
zypper in '!Firefox' '-htop'

# List available updates.
# By default, it shows only *installable* ones.
zypper list-updates
zypper lu --all

# Update installed resolvables.
zypper update
zypper up --download 'in-heaps' 'vivaldi-stable'

# List available patches.
# By default, it shows only *applicable* ones.
zypper list-patches
zypper lp --all

# Check whether there are applicable patches.
zypper patch-check
zypper pchk --with-optional

# Apply patches.
zypper patch

# Perform distribution upgrades.
zypper dist-upgrade
zypper dup --details --from 'factory' --from 'packman' --download 'as-needed' --remove-orphaned

# List unneded packages.
# E.g. older dependencies not used anymore.
zypper packages --unneeded
zypper pa --unneeded

# List installed resolvables.
zypper search --installed-only
zypper se -it 'pattern'

# List installed packages
zypper packages --installed-only
zypper pa -i

# List *manually* installed packages.
zypper packages --userinstalled
zypper pa -i | grep 'i+' | awk -F '|' '{print $3}' | sort -u

# List *automatically* installed packages.
zypper packages --autoinstalled

# Mark resolvables as *manually* installed.
zypper in -f 'zstd'
zypper in -f -t 'pattern' 'kde_plasma'
sed '/zstd/d' '/var/lib/zypp/AutoInstalled'

# Mark resolvables as *automatically* installed.
echo 'zstd' | tee -a '/var/lib/zypp/AutoInstalled'

# ---

# List repositories.
zypper repos
zypper lr -d --sort-by-priority

# Add repositories.
zypper addrepo --check --refresh --priority '90' 'https://repo.vivaldi.com/archive/vivaldi-suse.repo' 'vivaldi'
zypper ar -cfp '89' …

# Remove repositories.
zypper removerepo 'mozilla'
zypper rr '3'

# Rename repositories.
zypper renamerepo 'firefox' 'mozilla'
zypper nr '5' 'packman'

# Modify repositories.
# Disable with '-d'.
zypper modifyrepo -ef 'updates'
zypper mr -gp '98' '1' 'mozilla'
zypper mr -d 'packman' '4' 'https://repo.vivaldi.com/archive/vivaldi-suse.repo'
zypper mr -da

# ---

# Execute without user confirmation (non-interactively).
zypper --non-interactive …
zypper --non-interactive --auto-agree-with-licenses …

# Mark transactions in log files.
zypper --userdata 'comment-here' …

# Clean up installed kernel packages.
zypper purge-kernels --dry-run

# Clean up unneded packages.
# *Always* check what is being done.
# FIXME: flaky
zypper -q pa --unneeded \
| grep -E '^i\s+' | awk -F'|' '{gsub(" ", "", $0); print $3"="$4}' | sort -u \
| xargs zypper rm -uD

# Upgrade distribution's releases.
# Suggested to do this after:
# - all users logged off;
# - disabling the GUI (`systemctl stop 'display-manager.service'`).
sed -i 's|/15.5/|/$releasever/|g' '/etc/zypp/repos.d/'*'.repo' \
&& zypper ref \
&& zypper up \
&& zypper --releasever '15.6' ref \
&& zypper --releasever '15.6' dup \
&& reboot
```

## Concepts

The set of packages installed on a system is denoted as the _@System_ repository or _System Packages_.<br/>
In contrast to normal repositories, @System provides packages that can only be deleted.

Installed packages which do not belong to any available repository are denoted as _unwanted_, _orphaned_ or _dropped_.

One can specify the location of packages or repositories using any type of URI supported by `libzypp` (e.g. local paths,
ftp/https/other URI).<br/>
In addition, Zypper accepts openSUSE Build Service repositories in the `addrepo` command in the form of
`obs://project/platform` URI.

Resource objects are called _resolvables_.<br/>
They might be **packages**, **patches**, **patterns**, **products**, or basically any kind of object with dependencies
to other objects managed by `libzypp`.

If one does not request specific versions of resolvables during an action, Zypper's dependency solver will pick a
_reasonable_ one automatically.

## Repositories

The **lower** the number given to their `priority` setting, the **higher** the precedence of that repository.<br/>
This means that a repository with priority 90 will have precedence on repositories with the default priority of 99.

[Default (distribution) repositories][package repositories], [additional repositories][additional package repositories].

Repositories of interest:

| Name          | Repos' URL keys                                                                                                                                                                                                                                                                                                                                            | Repo files' URLs                                                                                  | Description                                                                  |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Mozilla       | `https://download.opensuse.org/repositories/mozilla/openSUSE_Tumbleweed/`<br/>`https://download.opensuse.org/repositories/mozilla/openSUSE_Leap_$releasever/`                                                                                                                                                                                              | [Tumbleweed](https://download.opensuse.org/repositories/mozilla/openSUSE_Tumbleweed/mozilla.repo) | Bleeding edge versions of Firefox, Thunderbird and all things Mozilla        |
| Packman (all) | `https://ftp.fau.de/packman/suse/openSUSE_Tumbleweed/`<br/>`https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_$releasever/`                                                                                                                                                                                                                    | [Tumbleweed](https://ftp.fau.de/packman/suse/openSUSE_Tumbleweed/packman.repo)                    | The largest external repository of openSUSE packages                         |
| Vivaldi       |                                                                                                                                                                                                                                                                                                                                                            | [All](https://repo.vivaldi.com/archive/vivaldi-suse.repo)                                         | A browser adapting to you, not the other way around.                         |
| KDE           | `https://download.opensuse.org/repositories/KDE:/Extra/openSUSE_Tumbleweed/`<br/>`https://download.opensuse.org/repositories/KDE:/Frameworks/openSUSE_Tumbleweed/`<br/>`https://download.opensuse.org/repositories/KDE:/Applications/KDE_Frameworks5_openSUSE_Tumbleweed/`<br/>`https://download.opensuse.org/repositories/KDE:/Extra/openSUSE_Leap_15.6/` |                                                                                                   | Bleeding edge versions of framework, Plasma, applications and all things KDE |

## Configuration

Default global configuration file: `/etc/zypp/zypp.conf`.<br/>
An alternate config file can be set using the `ZYPP_CONF=<PATH>` environment variable.

See [zypp configuration options] for details.

## Gotchas

Global options **must** be specified **before** the command name.<br/>
Command-specific options **must** be specified **after** the command name.

Zypper does not have for now a way to list **the content** of an **installed** package. Use [rpm] for this:

```sh
sudo rpm --query --list 'parallel'
```

## Distribution's release upgrade

> Tested on openSUSE Leap (15.5. to 15.6).

Suggested to do this **after**:

- All users logged off;
- Disabling the GUI (`systemctl stop 'display-manager.service'`).

Procedure:

1. Make sure no repository has the release version hardcoded:

   ```sh
   sudo sed -i 's|/15.5/|/$releasever/|g' '/etc/zypp/repos.d/'*'.repo'
   ```

1. Refresh the cache:

   ```sh
   sudo zypper refresh
   ```

1. Update the **current** release's packages:

   ```sh
   sudo zypper update
   ```

1. Refresh the cache again forcing the **new** release version:

   ```sh
   sudo zypper --releasever '15.6' refresh
   ```

1. Upgrade the whole distribution to the **new** release:

   ```sh
   sudo zypper --releasever '15.6' dist-upgrade
   ```

1. Reboot.

## Further readings

- [rpm]
- [How can I list all files which have been installed by an ZYpp/Zypper package?]
- [Managing software with command line tools]
- [Zypp configuration options]

### Sources

- [Package repositories]
- [Additional package repositories]
- [Command to clean out all unneeded autoinstalled dependencies]
- [System upgrade]
- [Zypper cheat sheet]
- [KDE repositories]
- [Zypper manual]
- [45 Zypper commands to manage 'Suse' Linux package management]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[rpm]: rpm.md

<!-- Upstream -->
[additional package repositories]: https://en.opensuse.org/Additional_package_repositories
[command to clean out all unneeded autoinstalled dependencies]: https://github.com/openSUSE/zypper/issues/116
[kde repositories]: https://en.opensuse.org/SDB:KDE_repositories
[managing software with command line tools]: https://documentation.suse.com/sles/15-SP5/html/SLES-all/cha-sw-cl.html
[package repositories]: https://en.opensuse.org/Package_repositories
[system upgrade]: https://en.opensuse.org/SDB:System_upgrade
[zypp configuration options]: https://doc.opensuse.org/projects/libzypp/HEAD/group__ZyppConfig.html
[zypper cheat sheet]: https://en.opensuse.org/images/1/17/Zypper-cheat-sheet-1.pdf
[zypper manual]: https://en.opensuse.org/SDB:Zypper_manual

<!-- Others -->
[45 zypper commands to manage 'suse' linux package management]: https://www.tecmint.com/zypper-commands-to-manage-suse-linux-package-management/
[how can i list all files which have been installed by an zypp/zypper package?]: https://unix.stackexchange.com/questions/162092/how-can-i-list-all-files-which-have-been-installed-by-an-zypp-zypper-package#239944
