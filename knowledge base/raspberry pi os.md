# Raspberry Pi OS

## Let it run containers

### Kernel containerization features

Enable containerization features in the kernel to be able to run containers as intended.

Add the following properties at the end of the line in `/boot/cmdline.txt`:

```sh
cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory
```

### Firewall settings

Switch Debian firewall to legacy config:

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
