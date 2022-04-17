# Magisk

## TL;DR

> This procedure works for a **OnePlus 5** phone.

1. download the os' recovery-flashable zip file
1. extract the `boot.img` file from the zip file
1. open the Magisk app
1. press the _Install_ button on the _Magisk_ card
1. choose _Select and Patch a File_ under _Method_
1. select the boot image; the Magisk app will patch the image to `[Internal Storage]/Download/magisk_patched_<random strings>.img`
1. copy the patched image to your computer using the file transfer mode or `adb`:

   ```shell
   adb pull /sdcard/Download/magisk_patched_<random strings>.img
   ```

1. reboot the device to the bootloader (fastboot)
1. flash the modified boot image:

   ```shell
   sudo fastboot flash boot path/to/modified/boot.img
   ```

1. reboot to the system

## Further readings

- [How to Install Magisk on your Android Phone]

[how to install magisk on your android phone]: https://www.xda-developers.com/how-to-install-magisk/
