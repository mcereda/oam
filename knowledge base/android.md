# Android

1. [TL;DR](#tldr)
1. [Applications of interest](#applications-of-interest)
1. [Enable _Developer options_](#enable-developer-options)
1. [Enable OEM unlocking](#enable-oem-unlocking)
1. [Enable USB debugging](#enable-usb-debugging)
1. [Google Pixel](#google-pixel)
   1. [Flash official images](#flash-official-images)
1. [Android Open Source Project (AOSP)](#android-open-source-project-aosp)
1. [GrapheneOS](#grapheneos)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install 'android-platform-tools'
```

</details>

<details>
  <summary>Usage</summary>

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

</details>

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
| [PingTools]     | Network utilities                                                                 |
| [Rethink]       | DNS and firewall                                                                  |
| [Signal]        | Privacy-focused messaging                                                         |

## Enable _Developer options_

> [!important]
> Must be done from **within** a working system.

1. Go to _Settings_ > _About phone_.
1. Click the _Build number_ menu entry repeatedly until it enables developer mode.

The new section will appear under _Settings_ > _System_, in the _Advanced_ section.

## Enable OEM unlocking

1. [Enable _Developer options_][Enable Developer options].
1. Go to _Settings_ > _System_ > _Developer options_.
1. Switch _OEM unlocking_ on.

## Enable USB debugging

1. [Enable _Developer options_][Enable Developer options].
1. Go to _Settings_ > _System_ > _Developer options_.
1. Switch _USB debugging_ on.

## Google Pixel

### Flash official images

Google provides the [Android Flash Tool] webUI to help flashing Pixel devices with official releases.

> [!important]
> Make sure no other `adb` process can connect to the device.\
> Close all other tabs that could do it (e.g., [GrapheneOS]' web installer), and kill the local server process with
> `adb kill-server`.

Refer to [Factory Images for Nexus and Pixel Devices] for manual operations.

## Android Open Source Project (AOSP)

Refer to [Android Open Source Project].

## GrapheneOS

> [!warning]
> Only supports [Google Pixels][Google Pixel] and a few more devices.

[Website][GrapheneOS / Website]

The [WebUSB-based installer][GrapheneOS / Web installer] is the recommended approach. Use a **chrome**-based browser.\
One can fallback to the [CLI install guide][GrapheneOS / CLI install guide] in case.

Generic installation steps:

1. Enable [OEM unlocking][Enable OEM unlocking] and [USB debugging][Enable USB debugging] on the device.
1. FIXME.

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
[Enable Developer options]: #enable-developer-options
[Enable OEM unlocking]: #enable-oem-unlocking
[Enable USB debugging]: #enable-usb-debugging
[Google Pixel]: #google-pixel
[GrapheneOS]: #grapheneos

<!-- Upstream -->
[ADB]: https://developer.android.com/studio/command-line/adb

<!-- Others -->
[Aegis]: https://getaegis.app
[Aftership]: https://www.aftership.com/mobile-app
[Ampere]: https://play.google.com/store/apps/details?id=com.gombosdev.ampere
[Android Flash Tool]: https://flash.android.com
[Android Open Source Project]: https://source.android.com/
[AuroraReach]: https://play.google.com/store/apps/details?id=com.aurorareach.app
[F-Droid]: https://f-droid.org
[Factory Images for Nexus and Pixel Devices]: https://developers.google.com/android/images
[FUTO keyboard]: https://keyboard.futo.org
[GrapheneOS / CLI install guide]: https://grapheneos.org/install/cli
[GrapheneOS / Web installer]: https://grapheneos.org/install/web
[GrapheneOS / Website]: https://grapheneos.org/
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
