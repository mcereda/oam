# Raspberry Pi OS

1. [Store files on the SD even when the overlay file system is active](#store-files-on-the-sd-even-when-the-overlay-file-system-is-active)
2. [Swap](#swap)
3. [Run containers](#run-containers)
   1. [Kernel containerization features](#kernel-containerization-features)
   2. [Firewall settings](#firewall-settings)
4. [Sources](#sources)

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

## Sources

- The [k3s] project page
- The [Build your very own self-hosting platform with Raspberry Pi and Kubernetes] series of articles
- [Run Kubernetes on a Raspberry Pi with k3s]
- Project's [issue 2067]

[build your very own self-hosting platform with raspberry pi and kubernetes]: https://kauri.io/build-your-very-own-self-hosting-platform-with-raspberry-pi-and-kubernetes/5e1c3fdc1add0d0001dff534/c
[issue 2067]: https://github.com/k3s-io/k3s/issues/2067#issuecomment-664052806
[k3s]: https://k3s.io/
[run kubernetes on a raspberry pi with k3s]: https://opensource.com/article/20/3/kubernetes-raspberry-pi-k3s
