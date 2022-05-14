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

## Further readings

- [Bluetooth]
- [Firewalld]
- [Systemd]

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
