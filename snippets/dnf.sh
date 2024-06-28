#!/usr/bin/env sh

sudo dnf makecache

sudo dnf list --available --showduplicates 'gitlab-runner'

sudo dnf check-update --bugfix --security

sudo dnf install 'https://prerelease.keybase.io/keybase_amd64.rpm'
sudo dnf --assumeyes install 'git-lfs'
sudo dnf --assumeyes install \
	"https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
	"https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

sudo dnf upgrade --security --sec-severity 'Critical' --downloadonly
sudo dnf -y upgrade --security --sec-severity 'Important'


sudo rpmkeys --import 'https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg'


cat <<-EOF | sudo tee -a /etc/yum.repos.d/vscodium.repo
	[gitlab.com_paulcarroty_vscodium_repo]
	name=gitlab.com_paulcarroty_vscodium_repo
	baseurl=https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/
	enabled=1
	gpgcheck=1
	repo_gpgcheck=1
	gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
EOF


# List files in packages
dnf repoquery -l 'nginx'
