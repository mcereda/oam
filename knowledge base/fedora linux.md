# Fedora GNU/Linux

## Table of contents <!-- omit in toc -->

1. [Enable the RPM Fusion repositories](#enable-the-rpm-fusion-repositories)
1. [Broadcom Wi-Fi drivers](#broadcom-wi-fi-drivers)
1. [Enable ZFS management](#enable-zfs-management)
1. [Use DNF from behind a proxy](#use-dnf-from-behind-a-proxy)
1. [Sources](#sources)

## Enable the RPM Fusion repositories

RPM Fusion provides software that the Fedora Project or Red Hat doesn't want to ship. That software is provided as precompiled RPMs for all current Fedora versions and current Red Hat Enterprise Linux or clones versions; you can use the RPM Fusion repositories with tools like yum and PackageKit.

These repositories are not available by default and need to be installed using a remote package:

```sh
# All flavours but Silverblue-based ones.
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Silverblue-base flavours.
sudo rpm-ostree install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

After enabling the repositories, you can add their _tainted_ versions for closed or restricted packages:

```sh
sudo dnf install rpmfusion-{free,nonfree}-release-tainted
sudo rpm-ostree install rpmfusion-{free,nonfree}-release-tainted
```

## Broadcom Wi-Fi drivers

After enabling the normal **and tainted** RPM fusion repositores, just install the `b43-firmware` package.

## Enable ZFS management

```sh
sudo dnf install http://download.zfsonlinux.org/fedora/zfs-release$(rpm -E %dist).noarch.rpm
sudo dnf install kernel-devel zfs
sudo systemctl start zfs-fuse.service
sudo zpool import -a
```

## Use DNF from behind a proxy

Either:

- add the line `sslverify=0` to `/etc/dnf/dnf.conf`; **not suggested**, but a quick fix
- add the proxie's certificate, in PEM format, to the `/etc/pki/ca-trust/source/anchors/` folder and then run `sudo update-ca-trust`.

## Sources

- [RPM fusion configuration]
- [DNF update from behind SSL inspection proxy]

<!--
  References
  -->

<!-- Others -->
[dnf update from behind ssl inspection proxy]: https://molo76.github.io/2017/07/04/dnf-update-behind-ssl-inspection-proxy.html
[rpm fusion configuration]: https://rpmfusion.org/Configuration
