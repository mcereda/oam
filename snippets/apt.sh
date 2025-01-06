#!/usr/bin/env sh

cat <<-EOF | sudo tee /etc/apt/sources.list.d/debian-stable.list
	deb     http://deb.debian.org/debian/ stable main contrib non-free
	#deb-src http://deb.debian.org/debian/ stable main contrib non-free

	deb     http://security.debian.org/debian-security stable-security main contrib non-free
	#deb-src http://security.debian.org/debian-security stable-security main contrib non-free

	# stable-updates, to get updates before a point release is made;
	# see https://www.debian.org/doc/manuals/debian-reference/ch02.en.html#_updates_and_backports
	deb     http://deb.debian.org/debian/ stable-updates main contrib non-free
	#deb-src http://deb.debian.org/debian/ stable-updates main contrib non-free

	# stable-backports, previously on backports.debian.org
	# apt expects the release codename for backports, not "stable"
	#deb     http://deb.debian.org/debian/ stable-backports main contrib non-free
	#deb-src http://deb.debian.org/debian/ stable-backports main contrib non-free
EOF
cat <<-EOF | sudo tee /etc/apt/sources.list.d/debian-testing.list
	deb     http://deb.debian.org/debian/ testing main contrib non-free
	#deb-src http://deb.debian.org/debian/ testing main contrib non-free

	deb     http://security.debian.org/debian-security testing-security main contrib non-free
	#deb-src http://security.debian.org/debian-security testing-security main contrib non-free

	# testing-updates, to get updates before a point release is made;
	# see https://www.debian.org/doc/manuals/debian-reference/ch02.en.html#_updates_and_backports
	deb     http://deb.debian.org/debian/ testing-updates main contrib non-free
	#deb-src http://deb.debian.org/debian/ testing-updates main contrib non-free

	# testing-backports, previously on backports.debian.org
	deb     http://deb.debian.org/debian/ testing-backports main contrib non-free
	#deb-src http://deb.debian.org/debian/ testing-backports main contrib non-free
EOF
cat <<-EOF | sudo tee /etc/apt/sources.list.d/debian-unstable.list
	deb     http://deb.debian.org/debian/ unstable main contrib non-free
	#deb-src http://deb.debian.org/debian/ unstable main contrib non-free
EOF
cat <<-EOF | sudo tee /etc/apt/preferences.d/90pin-to-release
	Package:       *
	Pin:           release n=testing
	Pin-Priority:  990

	Package:       *
	Pin:           release n=stable
	Pin-Priority:  500

	Package:       *
	Pin:           release n=bullseye
	Pin-Priority:  450

	Package:       *
	Pin:           release n=unstable
	Pin-Priority:  -1
EOF

sudo apt update

sudo apt install './keybase_amd64.deb'
sudo apt install --no-install-recommends 'psutils'
sudo apt install --assume-yes 'plasma-desktop' 'plasma-nm' 'dolphin-plugins' 'konsole' 'sddm-theme-debian-breeze' 'kate'
DEBIAN_FRONTEND='noninteractive' apt-get --assume-yes --target-release 'unstable' install 'kde-plasma-desktop'

sudo apt-mark auto $(sudo apt-mark showmanual)

sudo apt autoremove --purge
