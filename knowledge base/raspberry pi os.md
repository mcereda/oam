# Raspberry Pi OS

1. [First boot](#first-boot)
1. [Privilege escalation](#privilege-escalation)
1. [Disable WiFi and Bluetooth](#disable-wifi-and-bluetooth)
   1. [Through boot configuration](#through-boot-configuration)
   1. [Through rfkill](#through-rfkill)
   1. [Disable the related services](#disable-the-related-services)
   1. [Disable the stacks completely uninstalling the packages](#disable-the-stacks-completely-uninstalling-the-packages)
1. [Swap](#swap)
1. [Overlay filesystem mode](#overlay-filesystem-mode)
1. [Check for CPU throttling](#check-for-cpu-throttling)
1. [Check the board temperature](#check-the-board-temperature)
1. [Apply CPU governors](#apply-cpu-governors)
1. [Tuning](#tuning)
1. [Headless boot](#headless-boot)
    1. [The `wpa_supplicant` file](#the-wpa_supplicant-file)
    1. [Compute the password's hash](#compute-the-passwords-hash)
1. [Run containers](#run-containers)
    1. [Kernel containerization features](#kernel-containerization-features)
    1. [Firewall settings](#firewall-settings)
1. [Store files on the SD even when the overlay file system is active](#store-files-on-the-sd-even-when-the-overlay-file-system-is-active)
1. [Disable automatic upgrades](#disable-automatic-upgrades)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## First boot

Unless manually set from the Imager, on first boot the system will ask to create a new initial user.

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

## Swap

Disable the swap file:

```sh
sudo systemctl disable --now 'dphys-swapfile'
```

## Overlay filesystem mode

This enhances the performances, but all changes will be kept in RAM and lost after a reboot unless it is saved elsewhere.

Enable it using `raspi-config`. While enabled, `/root` is in RO and no data will be written to the card.

## Check for CPU throttling

See [Re: How to make sure the rpi cpu is not throttled down?].

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

E.g., `0x50005` means you are currently under-voltage and throttled. If you want to be able to support this use case without throttling you will need a better power supply.

If you never see a non-zero `get_throttled` value in normal usage, then you may not need to do anything.

## Check the board temperature

Use the `vcgencmd` utility with the `measure_temp` command:

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

### Compute the password's hash

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

## Further readings

- [`/boot/config.txt`][/boot/config.txt]
- [Overclocking]
- [`rfkill`][rfkill]
- [Country code search]
- [`k3s`][k3s]

## Sources

- [Prepare SD card for WiFi on headless Pi]
- [Run Kubernetes on a Raspberry Pi with k3s]
- Project's [issue 2067]
- [Re: How to make sure the rpi CPU is not throttled down?]
- [Timely tips for speeding up your Raspberry Pi]

<!-- project's references -->
[/boot/config.txt]: https://www.raspberrypi.org/documentation/configuration/config-txt/README.md
[overclocking]: https://www.raspberrypi.org/documentation/configuration/config-txt/overclocking.md

<!-- internal references -->
[k3s]: kubernetes/k3s.md
[rfkill]: rfkill.md

<!-- external references -->
[country code search]: https://www.iso.org/obp/ui/#search/code/
[how to disable your raspberry pi's wi-fi]: https://pimylifeup.com/raspberry-pi-disable-wifi/
[issue 2067]: https://github.com/k3s-io/k3s/issues/2067#issuecomment-664052806
[prepare sd card for wifi on headless pi]: https://raspberrypi.stackexchange.com/questions/10251/prepare-sd-card-for-wifi-on-headless-pi
[re: how to make sure the rpi cpu is not throttled down?]: https://www.raspberrypi.org/forums/viewtopic.php?t=152549#p999931
[run kubernetes on a raspberry pi with k3s]: https://opensource.com/article/20/3/kubernetes-raspberry-pi-k3s
[timely tips for speeding up your raspberry pi]: https://www.raspberry-pi-geek.com/Archive/2013/01/Timely-tips-for-speeding-up-your-Raspberry-Pi

<!-- imported, FIXME -->
[disabling bluetooth on raspberry pi]: https://di-marco.net/blog/it/2020-04-18-tips-disabling_bluetooth_on_raspberry_pi/
[ghollingworth/overlayfs]: https://github.com/ghollingworth/overlayfs
[how to disable onboard wifi and bluetooth on raspberry pi 3]: https://sleeplessbeastie.eu/2018/12/31/how-to-disable-onboard-wifi-and-bluetooth-on-raspberry-pi-3/
[how to disable wi-fi on raspberry pi]: https://raspberrytips.com/disable-wifi-raspberry-pi/
[how to make your raspberry pi 4 faster with a 64 bit kernel]: https://medium.com/for-linux-users/how-to-make-your-raspberry-pi-4-faster-with-a-64-bit-kernel-77028c47d653
[os documentation]: https://www.raspberrypi.org/documentation/computers/os.html
[re: raspbian jessie linux 4.4.9 severe performance degradati]: https://www.raspberrypi.org/forums/viewtopic.php?f=63&t=147781&start=50#p972790
[rp automatic updates]: https://raspberrypi.stackexchange.com/questions/102377/rp-automatic-updates#102379
[sd card power failure resilience ideas]: https://www.raspberrypi.org/forums/viewtopic.php?f=63&t=253104&p=1549229#p1549117
