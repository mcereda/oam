# Fedora GNU/Linux

## Enable the RPM Fusion repositories

RPM Fusion provides software that the Fedora Project or Red Hat doesn't want to ship. That software is provided as precompiled RPMs for all current Fedora versions and current Red Hat Enterprise Linux or clones versions; you can use the RPM Fusion repositories with tools like yum and PackageKit.

These repositories are not available by default and need to be installed using a remote package:

```shell
# All flavours but Silverblue-based ones.
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Silverblue-base flavours.
sudo rpm-ostree install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

After enabling the repositories, you can add their _tainted_ versions for closed or restricted packages:

```shell
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

## Sources

- [RPM fusion configuration]

[rpm fusion configuration]: https://rpmfusion.org/Configuration
