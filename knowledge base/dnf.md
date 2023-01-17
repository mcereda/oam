# DNF

## TL;DR

```sh
# Check whether updates are available.
dnf check-update
dnf check-update --bugfix --security

# Search package metadata for keywords.
# Keywords are matched as case-insensitive substrings.
# Globbing is supported during match.
# *All* keys are searched in package names and summaries.
dnf search 'rsync'

# Search packages that match at least *one* of the keys.
dnf search --all 'rsync'

# Install packages.
dnf install 'vim' 'jq-0.5.6-1.fc24'
dnf -y install 'Downloads/tito-0.6.2-1.fc22.noarch.rpm' \
  --setopt='install_weak_deps=False'
dnf install 'https://kojipkgs.fedoraproject.org/packages/tito/0.6.0/1.fc22/noarch/tito-0.6.0-1.fc22.noarch.rpm'
dnf install --advisory='FEDORA-2018-b7b99fe852' \*

# Install groups of packages.
dnf install '@docker'

# List packages.
dnf list 'sponge' 'ca-certificates'
dnf list --installed
dnf list --obsoletes

# Lists installed packages that are not available in any known repository.
dnf list --extras

# List packages which would be removed by the 'autoremove' command.
dnf list --autoremove

# Show packages' description and summary information
dnf info 'tar'

# Finds the packages providing a given specification.
dnf provides 'gzip'
dnf provides '/usr/bin/gzip'
dnf provides "gzip(x86-64)"

# Remove packages.
# Also removes their orphaned dependencies.
dnf remove 'parallel' 'kate'

# Refresh the cache for enabled repositories.
dnf makecache

# Show information about update advisories.
dnf updateinfo
dnf updateinfo list --security

# Upgrade packages to the latest version of theirs that is both available and
# resolvable.
dnf upgrade
dnf upgrade --bugfix
dnf upgrade --nobest --security
dnf upgrade --advisories='FEDORA-2021-74ebf2f06f,FEDORA-2021-83fdddca0f'

# List summary information about occurred transactions.
dnf history
dnf history '3..8'
dnf history list
dnf history list '4'

# Show extended information about transactions.
dnf history info '11'

# Perform the opposite operation of all those performed in the specified one.
# RPMDB's current state must allow it.
dnf history undo '5'

# Repeat the specified transaction.
# RPMDB's current state must allow it.
dnf history redo '5'

# Undo all transactions performed after the given one.
# RPMDB's current state must allow it.
dnf history rollback '7'
```

## Sources

- [Man page]
- [cheat.sh]
- [How to install only security and bugfixes updates with DNF]

<!-- project's references -->

<!-- external references -->
[cheat.sh]: https://cheat.sh/dnf
[how to install only security and bugfixes updates with dnf]: https://fedoramagazine.org/how-to-install-only-security-and-bugfixes-updates-with-dnf/
[man page]: https://man7.org/linux/man-pages/man8/dnf.8.html
