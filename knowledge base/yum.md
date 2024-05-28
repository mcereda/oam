# Yellowdog Updater Modified

Command-line utility for RPM used by Red Hat Linux and derivates.<br/>
Replaced by [DNF] in Fedora.

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
# Check for updates.
sudo yum check-update

# List available packages.
sudo yum --showduplicates list available 'gitlab-ee'

# Display information about packages.
sudo yum info 'gitlab-ee'

# Install packages.
sudo yum install 'buildah' 'jq-0.5.6-1.fc24'
sudo yum -y install 'Downloads/tito-0.6.2-1.fc22.noarch.rpm' --setopt='install_weak_deps=False'
sudo yum install 'https://kojipkgs.fedoraproject.org/packages/tito/0.6.0/1.fc22/noarch/tito-0.6.0-1.fc22.noarch.rpm'

# Upgrade packages.
sudo yum update 'gitlab-ee-16.11.3'

# Clear the cache.
sudo yum clean packages
sudo yum clean all
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
