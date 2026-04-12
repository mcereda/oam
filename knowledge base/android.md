# Android

1. [TL;DR](#tldr)
1. [Applications of interest](#applications-of-interest)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# List attached devices.
adb devices
adb devices -l

# Download files from an attached device.
adb pull '/path/to/device/file.img'
adb -s 'device_serial' pull '/path/to/device/file.img' '/path/to/local/file.img'

# Upload files to an attached device.
adb push 'path/to/local/file.img' 'path/to/device/dir'

# Install an application.
adb install 'path/to/file.apk'
adb -s 'device_serial' install 'path/to/file.apk'

# Issue shell commands.
adb shell 'command'

# Reboot devices to their 'fastboot' mode.
adb reboot bootloader

# Reset `adb` on the local host.
adb kill-server
```

With the device in fastboot mode:

```sh
# List attached devices.
fastboot devices

# Unlock the bootloader.
fastboot flashing unlock
fastboot oem unlock

# Lock the bootloader.
fastboot flashing lock
fastboot oem lock

# Flash a recovery image.
fastboot flash recovery 'path/to/recovery.img'

# Flash a boot image.
fastboot flash boot 'path/to/boot.img'

# Reboot to 'system' mode.
fastboot reboot
```

## Applications of interest

| Application     | Summary                                                                           |
| --------------- | --------------------------------------------------------------------------------- |
| [Aegis]         | Authenticator                                                                     |
| [Aftership]     | Package tracker                                                                   |
| [Ampere]        | Measures batteries charging and discharging current                               |
| [AuroraReach]   | Aurora alert                                                                      |
| [F-Droid]       | App store focused on free and open source mobile apps                             |
| [FUTO keyboard] | Offline, privacy-oriented keyboard                                                |
| [Immich]        | Self-hosted photo and video management solution                                   |
| [Logseq]        | Diary and knowledge management                                                    |
| [OpenKeyChain]  | OpenPGP provider                                                                  |
| [Organic Maps]  | Privacy-focused offline maps and GPS app for hiking, cycling, biking, and driving |
| [Phyphox]       | Use the phone for physics experiments                                             |
| [PingTools]     | Set of network utilities                                                          |
| [Rethink]       | DNS and firewall                                                                  |
| [Signal]        | Privacy-focused messaging                                                         |

## Further readings

- [ADB]
- [Using ADB and fastboot]

### Sources

- [How to Use ADB and Fastboot on Android]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Upstream -->
[ADB]: https://developer.android.com/studio/command-line/adb

<!-- Others -->
[Aegis]: https://getaegis.app
[Aftership]: https://www.aftership.com/mobile-app
[Ampere]: https://play.google.com/store/apps/details?id=com.gombosdev.ampere
[AuroraReach]: https://play.google.com/store/apps/details?id=com.aurorareach.app
[F-Droid]: https://f-droid.org
[FUTO keyboard]: https://keyboard.futo.org
[How to Use ADB and Fastboot on Android]: https://www.makeuseof.com/tag/use-adb-fastboot-android/
[Immich]: https://immich.app
[Logseq]: https://logseq.com
[OpenKeyChain]: https://www.openkeychain.org
[Organic Maps]: https://organicmaps.app
[Phyphox]: https://phyphox.org
[PingTools]: https://www.pingtools.org
[Rethink]: https://rethinkdns.com/app
[Signal]: https://signal.org/
[Using ADB and fastboot]: https://wiki.lineageos.org/adb_fastboot_guide
