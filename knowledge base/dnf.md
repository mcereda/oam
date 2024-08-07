# DNF

A.K.A. _Dandified YUM_.

Rewrite of [YUM] using [`libsolv`][libsolv].

1. [TL;DR](#tldr)
1. [Lock packages versions](#lock-packages-versions)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Global configuration file at `/etc/dnf/dnf.conf`.<br/>
Repositories `.repo` files reside under `/etc/yum.repos.d/`.<br/>
Configuration files use the INI format. **Some** options in the repository definition override the global settings for
DNF.

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
dnf install --advisory='FEDORA-2018-b7b99fe852' '*'

# Install groups of packages.
dnf install '@docker'

# List packages.
dnf list 'sponge' 'ca-certificates'
dnf list --installed
dnf list --obsoletes

# List all available versions of packages.
dnf list --available --showduplicates 'gitlab-runner'

# Lists installed packages that are not available in any known repository.
dnf list --extras

# List packages which would be removed by the 'autoremove' command.
dnf list --autoremove

# Show packages' description and summary information
dnf info 'tar'

# Show packages' dependencies.
dnf deplist 'docker-ce'

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

# Upgrade packages to the latest version of theirs that is both available and resolvable.
dnf upgrade
dnf upgrade --bugfix --exclude 'sshpass'
dnf upgrade --nobest --security
dnf upgrade --advisories='FEDORA-2021-74ebf2f06f,FEDORA-2021-83fdddca0f'
dnf upgrade --security --sec-severity 'Critical' --downloadonly
dnf -y upgrade --security --sec-severity 'Important'

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

# List configured repositories.
dnf repolist

# List packages in specific repositories.
dnf repo-pkgs 'oracle' list
dnf repository-packages 'mariadb' list 'mariadb-server'

# Downgrade packages.
dnf downgrade 'docker-ce-20.10.23-3.el8'

# Lock packages versions.
# Requires the 'versionlock' plugin.
dnf versionlock 'kernel-5.2.17-200.fc30'
dnf versionlock add 'docker-ce' 'docker-ce-cli' 'docker-ce-rootless-extras'

# List locked versions.
# Requires the 'versionlock' plugin.
dnf versionlock list

# Unlock packages versions.
# Requires the 'versionlock' plugin.
dnf versionlock delete 'kernel' 'docker-ce-20.10.23-3.el8'
```

## Lock packages versions

Use DNF's _versionlock_ plugin:

```sh
# Installation.
dnf install 'python3-dnf-plugin-versionlock'
```

```sh
# Get information about packages.
dnf info 'xfsprogs'
dnf repoquery -i 'openssh'
dnf repoquery --info 'bash'

# List available package versions.
dnf list --available --showduplicates 'gitlab-runner'
dnf repoquery 'httpd'

# List installed packages.
dnf list installed
rpm --query -a
rpmquery -a

# List locked versions.
dnf versionlock
dnf versionlock list

# Lock versions.
dnf versionlock 'kernel-5.2.17-200.fc30'
dnf versionlock add 'docker-ce' 'docker-ce-cli' 'docker-ce-rootless-extras'

# Unlock versions.
dnf versionlock delete 'kernel' 'docker-ce-20.10.23-3.el8'
dnf versionlock clear

# List files in packages.
dnf repoquery -l 'nginx'
dnf repoquery --list 'postgresql15'

# Get packages providing specific files.
dnf whatprovides '/usr/bin/psql'
dnf whatprovides '*/pgbench'

# Check packages' changelog.
dnf repoquery --changelog 'libvirt'
```

The _versionlock_ plugin maintains the constraints in its configuration file and automatically checks the constraints on every run.

Alternative could be to exclude the packages from one or more repositories or during the action, but the exclusion will not allow their installation in the first place.<br/>
Not to mention,

- acting on the repository files requires the `exclude` configuration key to be set for every repository the package could be found in;
- using the `--exclude` CLI option requires the option to be given at every run.

## Further readings

- [DNF Command Reference]
- [Man page]
- [DNF Configuration Reference]

### Sources

- [cheat.sh]
- [Using the DNF software package manager]
- [How to install only security and bugfixes updates with DNF]
- [How to use YUM/DNF to downgrade or rollback some package updates?]
- [How to lock kernel (or another package) on Fedora]
- [Appendix A. DNF commands list]
- [A quick guide to DNF for yum users]
- [How to list package files with dnf in Linux]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[yum]: yum.md

<!-- Upstream -->
[appendix a. dnf commands list]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/managing_software_with_the_dnf_tool/assembly_yum-commands-list_managing-software-with-the-dnf-tool
[dnf command reference]: https://dnf.readthedocs.io/en/latest/command_ref.html
[dnf configuration reference]: https://dnf.readthedocs.io/en/latest/conf_ref.html
[using the dnf software package manager]: https://docs.fedoraproject.org/en-US/quick-docs/dnf/

<!-- Others -->
[a quick guide to dnf for yum users]: https://opensource.com/article/18/8/guide-yum-dnf
[cheat.sh]: https://cheat.sh/dnf
[how to install only security and bugfixes updates with dnf]: https://fedoramagazine.org/how-to-install-only-security-and-bugfixes-updates-with-dnf/
[how to list package files with dnf in linux]: https://www.cyberciti.biz/faq/dnf-list-package-files-for-rhel-centosstream-feora-rocky-almalinux/
[how to lock kernel (or another package) on fedora]: https://robbinespu.gitlab.io/posts/locking-package-fedora/
[how to use yum/dnf to downgrade or rollback some package updates?]: https://access.redhat.com/solutions/29617
[libsolv]: https://github.com/openSUSE/libsolv
[man page]: https://man7.org/linux/man-pages/man8/dnf.8.html
