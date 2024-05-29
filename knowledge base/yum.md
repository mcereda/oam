# Yellowdog Updater, Modified

Command-line utility for RPM used by Red Hat Linux and derivates.<br/>
Replaced by [DNF] in Fedora 22+ and RHEL 8+.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Global configuration file at `/etc/yum/yum.conf`.<br/>
Repositories `.repo` files reside under `/etc/yum.repos.d/`.<br/>
Configuration files use the INI format. **Some** options in the repository definition override the global settings for
YUM.

<details>
  <summary>Usage</summary>

```sh
# Get help.
yum help
yum help localinstall

# Refresh the repositories' metadata.
yum makecache

# Check for updates.
yum check-update

# List packages.
yum --showduplicates list available 'gitlab-ee'

# Display information about packages.
yum info 'gitlab-ee'

# Install packages.
yum install 'buildah' 'jq-0.5.6-1.fc24'
yum -y install 'Downloads/tito-0.6.2-1.fc22.noarch.rpm' --setopt='install_weak_deps=False'
yum install 'https://kojipkgs.fedoraproject.org/packages/tito/0.6.0/1.fc22/noarch/tito-0.6.0-1.fc22.noarch.rpm'

# Upgrade packages.
yum upgrade 'gitlab-ee-16.11.3'
yum --obsoletes --best update

# Clear the cache.
yum clean packages
yum clean all

# Show enabled repositories.
yum repolist

# Display information about enabled repositories.
yum repoinfo
yum repoinfo 'kernel-livepatch'

# TODO
yum alias
yum autoremove
yum check
yum repoquery --deplist
yum distro-sync
yum downgrade
yum group | yum group summary
yum group info
yum group install
yum group list
yum group mark
yum group remove
yum group upgrade
yum localinstall
yum history
yum list
yum mark
yum module
yum provides
yum reinstall
yum remove
yum repository-packages
yum search
yum shell
yum swap
yum updateinfo
yum upgrade-minimal
```

</details>

## Further readings

- [DNF]

### Sources

- [What is yum and how do I use it?]
- [Yum Command Cheat Sheet for Red Hat Enterprise Linux]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[dnf]: dnf.md

<!-- Upstream -->
[what is yum and how do i use it?]: https://access.redhat.com/solutions/9934
[yum command cheat sheet for red hat enterprise linux]: https://access.redhat.com/articles/yum-cheat-sheet
