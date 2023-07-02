# Raspberry Pi OS

## Table of contents <!-- omit in toc -->

1. [First boot](#first-boot)
1. [Repositories](#repositories)
1. [Privilege escalation](#privilege-escalation)
1. [Disable WiFi and Bluetooth](#disable-wifi-and-bluetooth)
   1. [Through boot configuration](#through-boot-configuration)
   1. [Through rfkill](#through-rfkill)
   1. [Disable the related services](#disable-the-related-services)
   1. [Disable the stacks completely uninstalling the packages](#disable-the-stacks-completely-uninstalling-the-packages)
1. [Disable swap](#disable-swap)
1. [Disable automatic upgrades](#disable-automatic-upgrades)
1. [Overlay filesystem mode](#overlay-filesystem-mode)
   1. [Store files on the SD when the overlay file system is active](#store-files-on-the-sd-when-the-overlay-file-system-is-active)
1. [Checks](#checks)
   1. [Frequencies](#frequencies)
   1. [CPU throttling](#cpu-throttling)
   1. [Board temperature](#board-temperature)
1. [Apply CPU governors](#apply-cpu-governors)
1. [Tuning](#tuning)
1. [Headless boot](#headless-boot)
    1. [The `wpa_supplicant` file](#the-wpa_supplicant-file)
       1. [Compute the password's hash](#compute-the-passwords-hash)
1. [Run containers](#run-containers)
    1. [Kernel containerization features](#kernel-containerization-features)
    1. [Firewall settings](#firewall-settings)
1. [Troubleshooting](#troubleshooting)
    1. [LED warning flash codes](#led-warning-flash-codes)
    1. [Issues connecting to WiFi network using roaming features or WPA3](#issues-connecting-to-wifi-network-using-roaming-features-or-wpa3)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## First boot

Unless manually set from the Imager, on first boot the system will ask to create a new initial user.

## Repositories

[Repositories], [Mirrors].

## Privilege escalation

- Users in the `sudo` group can `sudo`.
- The initial user can `sudo` without being asked for a password by default.

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
   rfkill block 'wifi'
   rfkill block 'bluetooth'
   ```

1. check they are correctly soft-blocked:

   ```sh
   rfkill list
   ```

### Disable the related services

- `hciuart.service` and `bluetooth.service` for Bluetooth
- `wpa_supplicant.service` for WiFi

### Disable the stacks completely uninstalling the packages

```sh
sudo apt --assume-yes purge 'bluez'
sudo apt --assume-yes autoremove --purge
```

## Disable swap

Disable the swap file:

```sh
sudo systemctl disable --now 'dphys-swapfile'
```

## Disable automatic upgrades

Raspberry Pi OS has daily upgrades enabled by default. Check the second line of this command's output:

```sh
systemctl status 'apt-daily-upgrade.timer'
```

Check the time it was last run with the following:

```sh
stat -c '%z' '/var/lib/apt/daily-lock'
```

If the service is enabled, there should be a record of that in `/var/log/dpkg.log`.

To disable this, execute the following:

```sh
sudo systemctl mask 'apt-daily-upgrade'
sudo systemctl mask 'apt-daily'
sudo systemctl disable 'apt-daily-upgrade.timer'
sudo systemctl disable 'apt-daily.timer'
```

Using **_mask_** to prevent the above services from being re-enabled by some dependency.

Notice those are two separate services; they both run `/usr/lib/apt/apt.systemd.daily`, a shell script, with parameters install and update.

## Overlay filesystem mode

This enhances the performances, but all changes will be kept in RAM and lost after a reboot unless it is saved elsewhere.

Enable it using `raspi-config`. While enabled, `/root` is in RO and no data will be written to the card.

### Store files on the SD when the overlay file system is active

The files just need to be stored on a different file system from `/`. You can partition the SD and use that, or create a file and mount it as a virtual file system:

```sh
truncate -s '6G' 'file'
mkfs.ext4 'file'
mkdir 'mount/point'
sudo mount -t 'ext4' -o 'loop' 'file' 'mount/point'
sudo chown 'user':'group' 'mount/point'
touch 'mount/point/new-file'
```

## Checks

See [vcgencmd] for more information.

### Frequencies

```sh
# Current CPU frequency.
vcgencmd measure_clock arm

# Current GPU frequency.
vcgencmd measure_clock core

# Min set frequency per CPU core.
cat '/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq'
cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_min_freq

# Max set frequency per CPU core.
cat '/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq'
cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq

# Current set frequency per CPU core.
cat '/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq'
cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq
```

### CPU throttling

See also [Re: How to make sure the rpi cpu is not throttled down?].

```sh
$ vcgencmd get_throttled
throttled=0x0
```

The bits in this number represent the following:

| Bit | Hex value | Meaning                                                                            |
| --- | --------- | ---------------------------------------------------------------------------------- |
| 0   | 0x1       | Under-voltage detected; occurs when voltage drops below 4.63V; the Pi is throttled |
| 1   | 0x2       | Arm frequency capped; occurs with temp > 80˚C                                      |
| 2   | 0x4       | Currently throttled                                                                |
| 3   | 0x8       | Soft temperature limit active                                                      |
| 16  | 0x10000   | Under-voltage has occurred                                                         |
| 17  | 0x20000   | Arm frequency capping has occurred                                                 |
| 18  | 0x40000   | Throttling has occurred                                                            |
| 19  | 0x80000   | Soft temperature limit has occurred                                                |

`over-temperature` occurs with temp > 85˚C. The Pi is throttled.

Throttling removes turbo mode, which reduces core voltage and sets arm and gpu frequencies to a non-turbo value.

Capping just limits the CPU frequency (somewhere between 600MHz and 1200MHz) to try to avoid throttling.

If the board throttled but is not under-voltage, you can assume over-temperature; confirm this with `vcgencmd measure_temp`.

Sums of error codes mean multiple events occurred.<br/>
E.g., `0x50005` means you are currently under-voltage and throttled. If you want to be able to support this use case without throttling you will need a better power supply.

If you never see a non-zero `get_throttled` value in normal usage, then you may not need to do anything.

### Board temperature

```sh
$ vcgencmd measure_temp
temp=73.1'C
```

## Apply CPU governors

Until next boot:

```sh
echo 'ondemand' | sudo tee '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'
echo 'performance' | sudo tee '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'
echo 'powersave' | sudo tee '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'
```

Permanently:

```sh
sudo nano '/etc/init.d/raspi-config'
```

## Tuning

See [Timely tips for speeding up your Raspberry Pi].

## Headless boot

Manual procedure:

1. Image the SD card

   ```sh
   sudo dd bs='4M' if='/tmp/2019-09-26-raspbian-buster-lite.img' of='/dev/mmcblk0' status='progress' oflag='sync'
   ```

1. Mount the `boot` partition.
1. Create an empty `ssh` file in that partition.<br/>
   This will enable the `ssh` service at boot.
1. Create the `wpa_supplicant.conf` file in the same partition.<br/>
   This will be used to overwrite the same file in `/etc` on the OS.

   1. Follow the template below.
   1. [Optionally] fill the template with the password's hash for improved security

### The `wpa_supplicant` file

`wpa_supplicant.conf` template:

```ini
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=«your_ISO-3166-1_two-letter_country_code»

network={
    ssid="«your_SSID»"
    psk="«your_PSK»"
    key_mgmt=WPA-PSK
}
```

Replace `«your_ISO-3166-1_two-letter_country_code»` with your [ISO Country Code](https://www.iso.org/obp/ui/#search/code/) (such as CA for Canada), `«your_SSID»` with your wireless access point name and `«your_PSK»` with your wifi password.

Note that the `country`, `ctrl_interface` and `update_config` lines are required in file as created in `/boot`: if they are missing the system will not connect to the network. The above process can be repeated to correct the omissions.

`wpa_supplicant.conf` example:

```ini
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=IE

network={
    ssid="VM6371722"
    psk=77475166938e2ddc18bcde2a59d4b63810c0a05ddf9b931e4b0223b74e94e389  # psk="qqqqqqqqq"
    key_mgmt=WPA-PSK
}
```

#### Compute the password's hash

Use `wpa_passphrase`:

```
usage: wpa_passphrase <ssid> [passphrase]
If passphrase is left out, it will be read from stdin
```

The utility will prompt for the password, and will return the hexadecimal hash value. This hashed password is to be stored **without quotes** in the `/boot/wpa_supplicant.conf` file.

```sh
$ wpa_passphrase "ssid"
# reading passphrase from stdin
password
network={
    ssid="ssid"
    #psk="password"
    psk=77475166938e2ddc18bcde2a59d4b63810c0a05ddf9b931e4b0223b74e94e389
}
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
update-alternatives --set 'iptables'  '/usr/sbin/iptables-legacy'
update-alternatives --set 'ip6tables' '/usr/sbin/ip6tables-legacy'
```

## Troubleshooting

### LED warning flash codes

If a Raspberry Pi fails to boot or has to shut down for some reason, in most cases it will flash a LED a specific number of times to indicate what happened.<br/>
The LED will blink for a number of long flashes (0 or more), then short flashes, to indicate the exact status. In most cases, the pattern will repeat after a 2 second gap.

See the [configuration] page for updated information.

| Long flashes | Short flashes | Status                                 | Notes     |
| ------------ | ------------- | -------------------------------------- | --------- |
| 0            | 3             | Generic failure on boot                |           |
| 0            | 4             | `start*.elf` not found                 |           |
| 0            | 7             | Kernel image not found                 |           |
| 0            | 8             | SDRAM failure                          |           |
| 0            | 9             | Insufficient SDRAM                     |           |
| 0            | 10            | In HALT state                          |           |
| 2            | 1             | Partition not FAT                      |           |
| 2            | 2             | Failed to read from partition          |           |
| 2            | 3             | Extended partition not FAT             |           |
| 2            | 4             | File signature/hash mismatch           | Pi 4 only |
| 3            | 1             | SPI EEPROM error                       | Pi 4 only |
| 3            | 2             | SPI EEPROM is write protected          | Pi 4 only |
| 3            | 3             | I2C error                              | Pi 4 only |
| 3            | 4             | Secure-boot configuration is not valid |           |
| 4            | 4             | Unsupported board type                 |           |
| 4            | 5             | Fatal firmware error                   |           |
| 4            | 6             | Power failure type A                   |           |
| 4            | 7             | Power failure type B                   |           |

### Issues connecting to WiFi network using roaming features or WPA3

Check [raspbian's bug 1929746][raspbian bug 1929746] for more information.

Quick solutions:

- (quick 'n' dirty) disable roaming options and WPA3 in your router;
- (preferable) disable SAE (WPA3) and SWSUP (offload authentication to the firmware), and fast roaming:

  ```sh
  rmmod 'brcmfmac'
  modprobe 'brcmfmac' roamoff=1 feature_disable=0x82000
  ```

  Make it permanent in a `.conf` file in `/etc/modprobe.d/`:

  ```sh
  # /etc/modprobe.d/wifi_workaround.conf
  options brcmfmac roamoff=1 feature_disable=0x82000
  ```

Long term solution: none currently known.

## Further readings

- [`/boot/config.txt`][/boot/config.txt]
- [Overclocking]
- [`rfkill`][rfkill]
- [Country code search]
- [`k3s`][k3s]
- [Configuration]

## Sources

All the references in the [further readings] section, plus the following:

- [Prepare SD card for WiFi on headless Pi]
- [Run Kubernetes on a Raspberry Pi with k3s]
- Project's [issue 2067]
- [Re: How to make sure the rpi CPU is not throttled down?]
- [Timely tips for speeding up your Raspberry Pi]
- [Repositories]
- [Mirrors]

<!--
  references
  -->

<!-- project -->
[/boot/config.txt]: https://www.raspberrypi.org/documentation/configuration/config-txt/README.md
[configuration]: https://www.raspberrypi.com/documentation/computers/configuration.html
[mirrors]: https://www.raspbian.org/RaspbianMirrors
[overclocking]: https://www.raspberrypi.org/documentation/configuration/config-txt/overclocking.md
[repositories]: https://www.raspbian.org/RaspbianRepository
[vcgencmd]: https://www.raspberrypi.com/documentation/computers/os.html#vcgencmd

<!-- article sections -->
[further readings]: #further-readings

<!-- knowledge base -->
[k3s]: kubernetes/k3s.md
[rfkill]: rfkill.md

<!-- others -->
[country code search]: https://www.iso.org/obp/ui/#search/code/
[disabling bluetooth on raspberry pi]: https://di-marco.net/blog/it/2020-04-18-tips-disabling_bluetooth_on_raspberry_pi/
[ghollingworth/overlayfs]: https://github.com/ghollingworth/overlayfs
[how to disable onboard wifi and bluetooth on raspberry pi 3]: https://sleeplessbeastie.eu/2018/12/31/how-to-disable-onboard-wifi-and-bluetooth-on-raspberry-pi-3/
[how to disable wi-fi on raspberry pi]: https://raspberrytips.com/disable-wifi-raspberry-pi/
[how to disable your raspberry pi's wi-fi]: https://pimylifeup.com/raspberry-pi-disable-wifi/
[how to make your raspberry pi 4 faster with a 64 bit kernel]: https://medium.com/for-linux-users/how-to-make-your-raspberry-pi-4-faster-with-a-64-bit-kernel-77028c47d653
[issue 2067]: https://github.com/k3s-io/k3s/issues/2067#issuecomment-664052806
[os documentation]: https://www.raspberrypi.org/documentation/computers/os.html
[prepare sd card for wifi on headless pi]: https://raspberrypi.stackexchange.com/questions/10251/prepare-sd-card-for-wifi-on-headless-pi
[raspbian bug 1929746]: https://bugs.launchpad.net/raspbian/+bug/1929746
[re: how to make sure the rpi cpu is not throttled down?]: https://www.raspberrypi.org/forums/viewtopic.php?t=152549#p999931
[re: raspbian jessie linux 4.4.9 severe performance degradati]: https://www.raspberrypi.org/forums/viewtopic.php?f=63&t=147781&start=50#p972790
[rp automatic updates]: https://raspberrypi.stackexchange.com/questions/102377/rp-automatic-updates#102379
[run kubernetes on a raspberry pi with k3s]: https://opensource.com/article/20/3/kubernetes-raspberry-pi-k3s
[sd card power failure resilience ideas]: https://www.raspberrypi.org/forums/viewtopic.php?f=63&t=253104&p=1549229#p1549117
[timely tips for speeding up your raspberry pi]: https://www.raspberry-pi-geek.com/Archive/2013/01/Timely-tips-for-speeding-up-your-Raspberry-Pi
