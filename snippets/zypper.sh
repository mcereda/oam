#!/usr/bin/env sh

# Update the cache
sudo zypper refresh
sudo zypper ref 'updates'
sudo zypper ref --releasever '15.6'

# Search for resolvables
zypper search 'nmap'
zypper se -r 'mariadb-repo' 'mariadb'
zypper se -s 'kernel-default'
zypper se --details 'boinc-client'

# Display resolvables' detailed information
zypper info 'workrave'
zypper if -t 'patch' 'libzypp'
zypper if -t 'pattern' 'lamp_server'

# Install resolvables
sudo zypper install 'parallel'
sudo zypper in --no-confirm --download-in-heaps 'https://prerelease.keybase.io/keybase_amd64.rpm'
sudo zypper in --no-recommends 'gv' 'virtualbox-ose=2.0.6' '/root/ansible.rpm'
sudo zypper in -r 'https://repo.vivaldi.com/archive/vivaldi-suse.repo' 'vivaldi'
sudo zypper in -f 'amdgpu-dkms'

# Check the dependencies of *installed* resolvables are satisfied
zypper verify 'git-lfs'
zypper ve 'virtualbox'

# Remove resolvables
sudo zypper remove --clean-deps 'code'
sudo zypper rm -u 'zfs'
sudo zypper in '!Firefox' '-htop'

# Clean caches
sudo zypper clean --metadata
sudo zypper clean --all 'packman'

# List available udates
# By default, it shows only *installable* ones
zypper list-updates
zypper lu --all --releasever '15.6'

# Update installed resolvables.
sudo zypper update
sudo zypper up 'vivaldi-stable'

# Perform distribution upgrades.
sudo zypper dist-upgrade
sudo zypper dup --details --from 'factory' --from 'packman'
sudo zypper --releasever '15.6' --download-in-heaps dup

# List repositories
zypper repos
zypper lr -d --sort-by-priority

# Add repositories
sudo zypper addrepo --check --refresh --priority '90' 'https://repo.vivaldi.com/archive/vivaldi-suse.repo' 'vivaldi'

# Remove repositories
sudo zypper removerepo 'mozilla'
sudo zypper rr '3'

# Clean up installed kernel packages
zypper purge-kernels --dry-run

# Clean up unneded packages
# Always check what is being done
zypper packages --unneeded \
| awk -F'|' 'NR>4{gsub(" ", "", $0);print $3"="$4}' | sort -u \
| sudo xargs -p zypper rm -u

# Upgrade distribution's releases
sudo zypper refresh
sudo zypper update
sed -i 's|/15.5/|/${releasever}/|g' '/etc/zypp/repos.d/'*'.repo'
sudo zypper --releasever '15.6' refresh
sudo zypper --releasever '15.6' dist-upgrade
sudo reboot
