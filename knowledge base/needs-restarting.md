# Needs-restarting

`needs-restarting -r` returns 1 if a reboot is needed, and 0 if it is not.

## TL;DR

```shell
# Install.
sudo dnf install dnf-utils
sudo yum install yum-utils

# Check if a full reboot is required.
sudo needs-restarting -r

# Show what services need to be restarted.
sudo needs-restarting -s
```

```text
$ sudo needs-restarting
The following running processes use deleted files:

PID  | PPID | UID  | User       | Command                           | Service
-----+------+------+------------+-----------------------------------+----------------
731  | 1    | 488  | avahi      | avahi-daemon                      | avahi-daemon
736  | 1    | 490  | messagebus | dbus-daemon                       | dbus
…
6260 | 1756 | 1000 | mek        | kdeinit5                          | 

You may wish to restart these processes.
See 'man zypper' for information about the meaning of values in the above table.

Core libraries or services have been updated.
Reboot is required to ensure that your system benefits from these updates.
```

## Sources

- [Automatic Reboot on Kernel Update]

[automatic reboot on kernel update]: https://access.redhat.com/discussions/3106621#comment-1196821
