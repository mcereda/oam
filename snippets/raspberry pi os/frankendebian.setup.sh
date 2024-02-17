#!/bin/sh

for release in stable testing
do
	envsubst <<-EOF | sudo tee /etc/apt/sources.list.d/raspi.${release}.list
	deb http://raspbian.raspberrypi.org/raspbian/ ${release} main contrib non-free rpi

	# Uncomment line below then 'apt-get update' to enable 'apt-get source'
	#deb-src http://raspbian.raspberrypi.org/raspbian/ ${release} main contrib non-free rpi
	EOF
done

cat <<-EOF > /etc/apt/preferences.d/90pin-to-release
Package: *
Pin: release n=stable
Pin-Priority: 500

Package: *
Pin: release n=testing
Pin-Priority: 450

Package: *
Pin: release n=buster
Pin-Priority: 400
EOF
