# VBoxManage

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)

## TL;DR

```sh
# Create host-only virtual networks.
VBoxManage hostonlynet add --name='network_name' --enable \
  --netmask='255.255.255.0' --lower-ip=192.168.12.100 --upper-ip=192.168.12.200
```
