# Android

1. [TL;DR](#tldr)
1. [Applications of interest](#applications-of-interest)
1. [Common operations](#common-operations)
   1. [Enable _Developer options_](#enable-developer-options)
   1. [Enable OEM unlocking](#enable-oem-unlocking)
   1. [Enable USB debugging](#enable-usb-debugging)
1. [Multiple users](#multiple-users)
   1. [Guest user](#guest-user)
1. [Devices' specifics](#devices-specifics)
   1. [Fairphone](#fairphone)
   1. [Google Pixel](#google-pixel)
1. [Distributions](#distributions)
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

# List installed packages.
adb shell pm list packages
adb shell pm list packages | grep 'google'

# Backup packages.
adb shell pm path 'com.example.package'
adb pull '/data/app/.../base.apk' './backups/'

# Install packages.
adb install -r -d './backups/base.apk'  # restore from a backup

# Remove packages.
# Only for specific users. A factory reset restores them.
adb shell pm uninstall -k --user '0' 'com.example.package'

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
fastboot oem unlock
fastboot flashing unlock
fastboot flashing unlock_critical

# Lock the bootloader.
fastboot flashing lock_critical
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

## Common operations

### Enable _Developer options_

> [!important]
> Must be done from **within** a working system.

1. Go to _Settings_ > _About phone_.
1. Click the _Build number_ menu entry repeatedly until it enables developer mode.

The new section will appear under _Settings_ > _System_, in the _Advanced_ section.

### Enable OEM unlocking

1. [Enable _Developer options_][Enable Developer options].
1. Go to _Settings_ > _System_ > _Developer options_.
1. Switch _OEM unlocking_ on.

### Enable USB debugging

1. [Enable _Developer options_][Enable Developer options].
1. Go to _Settings_ > _System_ > _Developer options_.
1. Switch _USB debugging_ on.

## Multiple users

Refer to [Support multiple users].

A.K.A. _user profiles_.\
This feature is **disabled** by default.

Activating a device creates its first _system user_ (named _Owner_ by default), and starts settings things up in it.\
This user has special privileges, and settings that only it can set. It can **only** be removed via factory reset.

Android does support multiple users on a single Android device.\
The system keeps users and their own data (contacts, media store, home directory, etc) **isolated** from each other.
Each user has their **own** instances of apps, app data, profile data and encryption keys. Apps in a user profile
**cannot** see data in other profiles and can only communicate with other apps within that same user profile (with
**mutual** consent of the other apps). There is currently **no** way to directly share data between profiles.\
Creating a new user starts the device configuration for that user.

The system only shows the **currently active** user's notifications.

_Secondary users_ are all those users that are added to a device other than the system user.\
These users can be removed by the system user or by themselves, and **cannot** impact other users set up on the same
device. They are usually intended for sharing a device between multiple physical people.\
Each user owns its own application data and some user-level settings. They _can_ run in the background while other users
are active. The Owner user **always** keeps running, even when other users are active in the foreground.

_Profiles_ own their own application data and share some system-wide settings. They are subsets of a single user and are
tied to it. Users can have multiple profiles. If a user is deleted, its profiles are removed with it.

_Accounts_ are contained within and owned by a single user. Users do **not** require accounts to be functional.

_Applications_ have their own data and live in a user sandbox. Apps installed within the **same** user profile can
interact with each other via IPC. Apps installed in different user profiles cannot communicate at all.

_Managed profiles_ are created by an app to contain work data and apps. Managed **exclusively** by the profile's owner.\
Launcher, notifications, and recent tasks are shared by the parent user and the managed profile.

_Restricted profiles_ use accounts defined in the parent user.\
Only that user can control what apps are available on the restricted profile. Available only on tablets and tvs.

_Clone profiles_ enables running multiple instances of a single app on one device.\
[AOSP] doesn't provide end-to-end support for the feature and requires OEMs to complete it before shipping.

_Private profiles_ are sandboxed spaces separate from rest of the device. They can be locked separately from the Owner.\
A private profile can exist **only** for the Owner, on the same device, along with work profiles and clone profiles.\
When a private profile is unlocked, its apps become visible. These apps are hidden when locked.

The secondary users can be thought as non-root users in a GNU/Linux system (with Owner being almost `root`).\
Separating profiles by trust level (e.g. _trusted_/_untrusted_/_work_) works _usually_ better than separating them by
function (e.g. _banking_/_gaming_/_social_).

By default, Android supports up to 4 total users (3 + guest).\
Vendors can customize this limit.

### Guest user

Temporary secondary user. There can be only one at any time.\
Its settings have an explicit option that enables quickly deleting it when its usefulness is over.

## Devices' specifics

### Fairphone

[Register every product][Fairphone / Register your product] as soon as they arrive to start the extended warranty.\
Check their state in the [Summary page][Fairphone / Warranty summary].

Fairphone considers [unlocking the bootloader][How to unlock or lock your Fairphone's bootloader] an essential product
feature.\
Users can [install alternative OSes][Alternative operating systems for Fairphone owners] on a device. The warranty will
**not** cover issues occurring while the device runs the alternative OS, but
[it does continue as normal][How alternative operating systems affect your Fairphone warranty] once the original
software is restored. Their repair center can restore the original OS for a fee.

Refer to [How to manually install Android on your Fairphone] for instructions on how to restore the original OS.\
Refer to [/e/OS / Devices] instead if it came with /e/OS.

### Google Pixel

Pixel devices ship with exclusive [closed-source
features][Pixel Drop: Here's everything new added to Google Pixel devices] like the following:

- Call and message screening with scam detection.
- Specialized camera app (Pixel Camera), with modes like astrophotography and time-lapse.
- [_Bypass charging_][Pixel phones now support bypass charging when set to the 80% charging limit].\
  Once the battery reaches the set charging limit (usually 80%), power from the charger is routed **directly** to the
  phone's components. It completely bypasses the battery, which sits idle and neither charges nor discharges.
- A [Native Linux terminal
  application][Android's Linux Terminal app is now widely available on Pixels, and here's how to get it] that grants
  access to a full-fledged Debian-based environment, similar to the Windows Subsystem for Linux.
- DisplayPort support with desktop and mirror modes.

Such features came to Pixel devices first, and only _some_ of them have been later ported to [AOSP].

Google provides the [Android Flash Tool] webUI to help flashing Pixel devices with official releases.

> [!important]
> Make sure no other `adb` process can connect to the device.\
> Close all other tabs that could do it (e.g., [GrapheneOS]' web installer), and kill the local server process with
> `adb kill-server`.

Refer to [Factory Images for Nexus and Pixel Devices] for manual operations.

## Distributions

### Android Open Source Project (AOSP)

Refer to [Android Open Source Project].

### GrapheneOS

> [!warning]
> Only supports [Google Pixels][Google Pixel] and a few more devices.

[Website][GrapheneOS / Website]

The [WebUSB-based installer][GrapheneOS / Web installer] is the recommended approach. Use a **chrome**-based browser.\
One can fallback to the [CLI install guide][GrapheneOS / CLI install guide] in case.

Generic installation steps:

1. Enable [OEM unlocking][Enable OEM unlocking] and [USB debugging][Enable USB debugging] on the device.
1. FIXME.

[Multiple users]' management improves to allow to up to 31 secondary users, optionally configure them to forward their
notifications to the currently active profile, reuse apps between profiles, and other features.

Most of GrapheneOS' default apps are available in Google's Play Store (and hence in those app stores that mirror it).

## Further readings

- [ADB]
- [Using ADB and fastboot]

### Sources

- [How to Use ADB and Fastboot on Android]
- [System Purifier]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[AOSP]: #android-open-source-project-aosp
[Enable Developer options]: #enable-developer-options
[Enable OEM unlocking]: #enable-oem-unlocking
[Enable USB debugging]: #enable-usb-debugging
[Google Pixel]: #google-pixel
[GrapheneOS]: #grapheneos
[Multiple users]: #multiple-users

<!-- Upstream -->
[ADB]: https://developer.android.com/studio/command-line/adb
[Support multiple users]: https://source.android.com/docs/devices/admin/multi-user

<!-- Others -->
[/e/OS / Devices]: https://doc.e.foundation/devices/
[Aegis]: https://getaegis.app
[Aftership]: https://www.aftership.com/mobile-app
[Alternative operating systems for Fairphone owners]: https://support.fairphone.com/hc/en-us/articles/38232029008786-Alternative-operating-systems-for-Fairphone-owners
[Ampere]: https://play.google.com/store/apps/details?id=com.gombosdev.ampere
[Android Flash Tool]: https://flash.android.com
[Android Open Source Project]: https://source.android.com/
[Android's Linux Terminal app is now widely available on Pixels, and here's how to get it]: https://www.androidauthority.com/android-linux-terminal-app-available-3532999/
[AuroraReach]: https://play.google.com/store/apps/details?id=com.aurorareach.app
[F-Droid]: https://f-droid.org
[Factory Images for Nexus and Pixel Devices]: https://developers.google.com/android/images
[Fairphone / Register your product]: https://www.fairphone.com/warranty/start
[Fairphone / Warranty summary]: https://www.fairphone.com/warranty/summary
[FUTO keyboard]: https://keyboard.futo.org
[GrapheneOS / CLI install guide]: https://grapheneos.org/install/cli
[GrapheneOS / Web installer]: https://grapheneos.org/install/web
[GrapheneOS / Website]: https://grapheneos.org/
[How alternative operating systems affect your Fairphone warranty]: https://support.fairphone.com/hc/en-us/articles/14487777708946-How-alternative-operating-systems-affect-your-Fairphone-warranty
[How to manually install Android on your Fairphone]: https://support.fairphone.com/hc/en-us/articles/18896094650513-How-to-manually-install-Android-on-your-Fairphone
[How to unlock or lock your Fairphone's bootloader]: https://support.fairphone.com/hc/en-us/articles/10492476238865-How-to-unlock-or-lock-your-Fairphone-s-bootloader
[How to Use ADB and Fastboot on Android]: https://www.makeuseof.com/tag/use-adb-fastboot-android/
[Immich]: https://immich.app
[Logseq]: https://logseq.com
[OpenKeyChain]: https://www.openkeychain.org
[Organic Maps]: https://organicmaps.app
[Phyphox]: https://phyphox.org
[PingTools]: https://www.pingtools.org
[Pixel Drop: Here's everything new added to Google Pixel devices]: https://www.androidauthority.com/google-pixel-feature-drop-3360934/
[Pixel phones now support bypass charging when set to the 80% charging limit]: https://www.androidauthority.com/pixel-bypass-charging-3507373/
[Rethink]: https://rethinkdns.com/app
[Signal]: https://signal.org/
[System Purifier]: https://github.com/orailnoor/sys-purifier
[Using ADB and fastboot]: https://wiki.lineageos.org/adb_fastboot_guide
