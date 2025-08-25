#!/usr/bin/env fish

# install tools
apt install 'policycoreutils'

# check status
getenforce
sestatus

# change enforcement
# requires a reboot to take place
sed -i'.bak' 's/^SELINUX\s*=\s*[a-z]*/SELINUX=permissive/' '/etc/selinux/config'
sed -i'.bak' -E 's/^(SELINUX\s*=\s*)[a-z]*/\1disabled/' '/etc/selinux/config'
