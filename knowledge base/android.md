# Android

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
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

## Further readings

- [ADB]
- [Using ADB and fastboot]

## Sources

All the references in the [further readings] section, plus the following:

- [How to Use ADB and Fastboot on Android]

<!-- upstream -->
[adb]: https://developer.android.com/studio/command-line/adb

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
<!-- external references -->
[how to use adb and fastboot on android]: https://www.makeuseof.com/tag/use-adb-fastboot-android/
[using adb and fastboot]: https://wiki.lineageos.org/adb_fastboot_guide
