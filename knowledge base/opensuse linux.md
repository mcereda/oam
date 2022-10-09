# OpenSUSE

## Enable Bluetooth pairing on boot

1. enable the `bluetooth` service on boot
1. install `bluez-auto-enable-devices`; this will create the configuration file `/etc/bluetooth/main.conf`

Also see specific settings in the [Bluetooth] KB.

## Enable SSH access from outside after installation

Open port 22 on the firewall:

- using Yast:

  1. open _Yast2_ > _Firewall_
  1. make sure your interfaces are appointed to the _External_ zone
  1. check _ssh_ is in the _Allowed services_ column and add it to the list if not
  1. save the configuration and exit (make sure the firewall is reloaded on exit)

- using [firewall-cmd][firewalld] on the command line:

  ```sh
  sudo firewall-cmd --add-port=22/tcp --permanent
  ```

Start the SSH daemon:

- using Yast: open _Yast2_ > _System services_ and enable _SSHD_
- using [systemctl][systemd] on the command line:

  ```sh
  sudo systemctl enable --now sshd.service
  ```

## Raspberry Pi

Install the OS from another computer capable of reading and writing SD cards.

Given `/dev/sdb` being a SD card, use the following:

```sh
curl -C - -L -o opensuse.raw.xz http://download.opensuse.org/ports/aarch64/tumbleweed/appliances/openSUSE-Tumbleweed-ARM-JeOS-raspberrypi.aarch64.raw.xz
xzcat opensuse.raw.xz \
 | sudo dd bs=4M of=/dev/sdb iflag=fullblock oflag=direct status=progress \
 && sync
```

Insert the SD card in the Raspberry Pi and power it on. The network is configured to get an IP address on `eth0` using DHCP.

Connect using SSH and login using `root:linux`.

### Firmware update from a running system

```sh
# Check for an updated firmware.
sudo rpi-eeprom-update

# Install the new version and reboot.
sudo rpi-eeprom-update -a && sync && reboot
```

## Rollback from a bootable snapshot

Do as follows:

1. boot the system
1. in GRUB's boot menu, choose _Bootable snapshots_
1. select the snapshot you want to boot into; the list of snapshots is listed by date, the most recent snapshot being listed first
1. log in to the system
1. carefully check whether everything works as expected

   > You cannot write to any directory that is part of the snapshot. Data you write to other directories will not get lost, regardless of what you do next.

Depending on whether you want to perform the rollback or not, choose your next step:

- if the system is in a state where you do **not** want to do a rollback, reboot and boot again into a different snapshot, or start the rescue system.
- to perform the rollback, run

  ```sh
  sudo snapper rollback
  ```

  and reboot

On the boot screen, choose the **default** boot entry to reboot into the reinstated system.

A snapshot of the file system status before the rollback is created, and the default subvolume for root will be replaced with a fresh read-write snapshot.

## Further readings

- [Bluetooth]
- [Firewalld]
- [Systemd]
- [System Recovery and Snapshot Management with Snapper]

## Sources

- [OpenSSH basics]
- [Bluetooth on boot]
- [Raspberry Pi4]

<!-- further readings -->

[bluetooth]: bluetooth.md#bluetooth-devices-cannot-be-used-at-login
[firewalld]: firewalld.md
[systemd]: systemd.md

[bluetooth on boot]: https://www.reddit.com/r/openSUSE/comments/eoozm2/comment/feetqpn/
[openssh basics]: https://en.opensuse.org/SDB:OpenSSH_basics
[raspberry pi4]: https://en.opensuse.org/openSUSE:Raspberry_Pi
[system recovery and snapshot management with snapper]: https://documentation.suse.com/sles/12-SP4/html/SLES-all/cha-snapper.html
