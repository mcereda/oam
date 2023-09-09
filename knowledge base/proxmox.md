# Proxmox

## Table of contents <!-- omit in toc -->

1. [Management port](#management-port)
1. [Disk passthrough](#disk-passthrough)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Management port

One NIC is used by Proxmox as _management port_.<br/>
This one is given a fixed IP address and bridged from inside the system.

## Disk passthrough

To allow for disk suspension and SMART checks from a VM, Proxmox needs to **directly** attach the disks to it.

Add all SATA disks to the VM with ID 100:

```sh
$ lsblk -do 'NAME,SIZE,TYPE,MODEL,SERIAL' -I '8'
NAME  SIZE TYPE MODEL              SERIAL
sda   3.6T disk ST4000VN008-2DR166 ZGY9WA2F
sdb   3.6T disk ST4000VN008-2DR166 ZGY9WDD5
sdc   3.6T disk ST4000VN008-2DR166 ZGY9WL4Z
sdd   3.6T disk ST4000VN008-2DR166 ZGY9W66G

$ qm set 100 -sata0 /dev/disk/by-id/ata-ST4000VN008-2DR166_ZGY9WA2F
$ qm set 100 -sata1 /dev/disk/by-id/ata-ST4000VN008-2DR166_ZGY9WDD5
$ qm set 100 -sata2 /dev/disk/by-id/ata-ST4000VN008-2DR166_ZGY9WL4Z
$ qm set 100 -sata3 /dev/disk/by-id/ata-ST4000VN008-2DR166_ZGY9W66G
```

## Further readings

- [Website]
- [Renaming a PVE node]

## Sources

All the references in the [further readings] section, plus the following:

- [How to run TrueNAS on Proxmox?]

<!--
  References
  -->

<!-- Upstream -->
[renaming a pve node]: https://pve.proxmox.com/wiki/Renaming_a_PVE_node
[website]: https://www.proxmox.com/en/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[how to run truenas on proxmox?]: https://www.youtube.com/watch?v=M3pKprTdNqQ
