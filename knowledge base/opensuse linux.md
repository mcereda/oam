# OpenSUSE

## Table of contents <!-- omit in toc -->

1. [Enable Bluetooth pairing on boot](#enable-bluetooth-pairing-on-boot)
1. [Enable SSH access from outside after installation](#enable-ssh-access-from-outside-after-installation)
1. [Raspberry Pi](#raspberry-pi)
   1. [Firmware update from a running system](#firmware-update-from-a-running-system)
1. [Rollback from a bootable snapshot](#rollback-from-a-bootable-snapshot)
1. [Firefox MP4/H.264 video support](#firefox-mp4h264-video-support)
1. [Docker images](#docker-images)
1. [Further readings](#further-readings)
1. [Sources](#sources)

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

## Firefox MP4/H.264 video support

To deal with [patent problems][information about the h.264 patent license], neither Firefox nor openSUSE provides the H264 codec required by fresh new openSUSE installation to play some video formats on the web.<br/>
The Packman and VLC repositories provide the needed `libav` packages. Install those libraries to let Firefox use them to decode MP4/H.264 video.

```sh
zypper install 'libavcodec60' 'libavdevice60' 'libavformat60'
```

openSUSE provides `ffmpeg` and `libav` packages like `libavcodec56`, but in them all patent related codecs were removed making them unable to play MP4/H.264 video. That is why one needs to upgrade these packages with their version in the Packman or VLC repositories.

Go to this [Simple WebRTC H264 check page] to check if Firefox can play H.264 videos after installation.

## Docker images

OpenSUSE's official container images are created and stored in [SUSE's container registry][container images built by the open build service]:

```sh
docker run -ti --rm --name 'tw' 'registry.opensuse.org/opensuse/tumbleweed'
```

## Further readings

- [Zypper]
- [Bluetooth]
- [Firewalld]
- [Systemd]
- [System Recovery and Snapshot Management with Snapper]
- [Container Images built by the Open Build Service]

## Sources

All the references in the [further readings] section, plus the following:

- [OpenSSH basics]
- [Bluetooth on boot]
- [Raspberry Pi4]
- [Firefox MP4/H.264 video support]
- [Information about the H.264 patent license]
- [Simple WebRTC H264 check page]

<!--
  References
  -->

<!-- Upstream -->
[container images built by the open build service]: https://registry.opensuse.org/cgi-bin/cooverview
[firefox mp4/h.264 video support]: https://en.opensuse.org/SDB:Firefox_MP4/H.264_Video_Support
[openssh basics]: https://en.opensuse.org/SDB:OpenSSH_basics
[raspberry pi4]: https://en.opensuse.org/openSUSE:Raspberry_Pi
[system recovery and snapshot management with snapper]: https://documentation.suse.com/sles/12-SP4/html/SLES-all/cha-snapper.html

<!-- Knowledge base -->
[bluetooth]: bluetooth.md#bluetooth-devices-cannot-be-used-at-login
[firewalld]: firewalld.md
[systemd]: systemd.md
[zypper]: zypper.md

<!-- Others -->
[bluetooth on boot]: https://www.reddit.com/r/openSUSE/comments/eoozm2/comment/feetqpn/
[information about the h.264 patent license]: https://www.fsf.org/licensing/h264-patent-license
[simple webrtc h264 check page]: https://mozilla.github.io/webrtc-landing/pc_test_no_h264
