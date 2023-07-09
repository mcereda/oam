# Beowulf cluster example

## Table of contents <!-- omit in toc -->

1. [Requirements](#requirements)

## Requirements

- VirtualBox
- A host-only virtual network (`VirtualBox Host-Only Ethernet Adapter`, address space `192.168.56.0/24`)
- An SSH key pair (files `id_ed25519` and `id_ed25519.pub`, create it with the command below)

  ```sh
  ssh-keygen -f 'id_ed25519' -N '' -C 'controller'
  ```

- An SSH config file ([`ssh_config.txt`][ssh_config.txt])
- A list of hosts for MPICH ([`mpi_hosts.txt`][mpi_hosts.txt]) containing the IP addresses of the workers

When up, execute the command below and enjoy:

```sh
vagrant ssh -c 'mpiexec -f mpi_hosts -n 3 hostname'
```

<!--
  References
  -->

<!-- Files -->
[mpi_hosts.txt]: mpi_hosts.txt
[ssh_config.txt]: ssh_config.txt
