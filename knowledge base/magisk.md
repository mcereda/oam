# Magisk

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

> This procedure worked for the following devices:
>
> - OnePlus One
> - OnePlus 5

## TL;DR

1. download and flash the os' recovery-flashable zip file
1. start the newly installed system
1. download and install the [latest version][releases] of Magisk's app
1. open Magisk
1. check the value of _Ramdisk_

If the value of _Ramdisk_ is **_yes_**:

1. extract the `boot.img` or `init_boot.img` file from the firmware's zip file
1. check if the firmware also has a `vbmeta.img` or `vbmeta_*.img` file
1. press the **_Install_** button in the Magisk app
1. if the firmware did **NOT** have a `vbmeta` image file, check the _Patch vbmeta in boot image_ option
1. hit **_Next_** in the Options section
1. choose _Select and Patch a File_ in the Method section
1. select the boot image
1. hit **_Let's go_**
1. flash the patched boot image

If the value of _Ramdisk_ is **_no_**, follow the instructions at [magisk in recovery](https://topjohnwu.github.io/Magisk/install.html#magisk-in-recovery)

Now:

1. Flash the patched boot image:

   - from the recovery, or
   - from your computer with `adb` and `fastboot`

1. reboot to the system

To flash the patched boot image from your computer with `adb` and `fastboot`:

1. copy the patched boot image to your computer using the file transfer mode or `adb`:

   ```sh
   adb pull '/sdcard/Download/magisk_patched_<random strings>.img'
   ```

1. reboot the device to the bootloader (fastboot)
1. flash the modified boot image:

   ```sh
   fastboot flash boot 'path/to/modified/boot.img'
   ```

1. if the firmware **HAD** a separate `vbmeta` image file, patch the `vbmeta` partition:

   ```sh
   fastboot flash vbmeta --disable-verity --disable-verification 'path/to/vbmeta.img'
   ```

## Further readings

- [How to Install Magisk on your Android Phone]
- [Magisk install]

<!-- upstream -->
[releases]: https://github.com/topjohnwu/Magisk/releases

<!-- internal references -->

<!-- external references -->
[how to install magisk on your android phone]: https://www.xda-developers.com/how-to-install-magisk/
[magisk install]: https://topjohnwu.github.io/Magisk/install.html
