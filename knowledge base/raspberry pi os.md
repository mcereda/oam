# Raspberry Pi OS

1. [Disable WiFi and Bluetooth](#disable-wifi-and-bluetooth)
   1. [Through boot configuration](#through-boot-configuration)
   1. [Through rfkill](#through-rfkill)
1. [Swap](#swap)
1. [Run containers](#run-containers)
   1. [Kernel containerization features](#kernel-containerization-features)
   1. [Firewall settings](#firewall-settings)
1. [Store files on the SD even when the overlay file system is active](#store-files-on-the-sd-even-when-the-overlay-file-system-is-active)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Disable WiFi and Bluetooth

### Through boot configuration

Disable one or both in the `all` section of `/boot/config.txt`:

```ini
[all]
dtoverlay=disable-wifi
dtoverlay=disable-bt
```

### Through rfkill

1. block one or both:

   ```sh
   rfkill block wifi
   rfkill block bluetooth
   ```

1. check they are correctly soft-blocked:

   ```sh
   rfkill list
   ```

## Swap

Disable the swap file.

```sh
sudo systemctl disable --now 'dphys-swapfile'
```

## Run containers

1. enable the kernel's containerization feature
1. disable swap
1. if kubernetes is involved, set up the firewall to use the legacy configuration

### Kernel containerization features

Enable containerization features in the kernel to be able to run containers as intended.

Add the following properties at the end of the line in `/boot/cmdline.txt`:

```sh
cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
```

```sh
sed -i '/cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/!s/\s*$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1&/' /boot/cmdline.txt
```

### Firewall settings

Switch Debian firewall to use the legacy configuration:

```sh
update-alternatives --set iptables  /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
```

## Store files on the SD even when the overlay file system is active

The files just need to be stored on a different file system from `/`. You can partition the SD and use that, or create a file and mount it as a virtual file system:

```sh
truncate -s '6G' 'file'
mkfs.ext4 'file'
mkdir 'mount/point'
sudo mount -t 'ext4' -o 'loop' 'file' 'mount/point'
sudo chown 'user':'group' 'mount/point'
touch 'mount/point/new-file'
```

## Further readings

- [rfkill]

## Sources

- The [k3s] project page
- [Run Kubernetes on a Raspberry Pi with k3s]
- Project's [issue 2067]

<!-- project's references -->

<!-- internal references -->
[k3s]: kubernetes/k3s.md
[rfkill]: rfkill.md

<!-- external references -->
[how to disable your raspberry pi's wi-fi]: https://pimylifeup.com/raspberry-pi-disable-wifi/
[issue 2067]: https://github.com/k3s-io/k3s/issues/2067#issuecomment-664052806
[run kubernetes on a raspberry pi with k3s]: https://opensource.com/article/20/3/kubernetes-raspberry-pi-k3s
