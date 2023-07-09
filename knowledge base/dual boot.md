# Dual boot

The process was conducted on a Dell XPS 13 2-in-1 7390 (2019) with specs:

- CPU: i7-1065G7
- Screen: 4K Touch
- RAM: 32 GB
- Drive: 1TB NVMe ssd
- Windows 10 Home license
- BIOS version: 1.14.0

Notes:

- FIXME: Suprisingly, Ubuntu's update manager supports BIOS updates out of the box (make sure you're connected to power then run `sudo fwupdmgr refresh; sudo fwupdmgr update`)

This installation did **not** require to disable TPM nor Secure Boot.

Steps for all procedures:

1. in Windows:
   - shrink the system partition to make space for linux
   - disable fast boot
1. in the bios, change disk mode from Intel's _RAID_ (Rapid .. .. Disk) to **AHCI** (.. .. .. ..)

## Table of contents <!-- omit in toc -->

1. [Create the installation media](#create-the-installation-media)
1. [Fedora](#fedora)
1. [Ubuntu](#ubuntu)
   1. [Partitioning](#partitioning)
   1. [Install Windows](#install-windows)
   1. [Install Ubuntu](#install-ubuntu)
   1. [Ubuntu Tweaks for XPS 9560](#ubuntu-tweaks-for-xps-9560)
   1. [Reinstall Ubuntu](#reinstall-ubuntu)
   1. [Additional notes](#additional-notes)

## Create the installation media

1. Create Windows installation USB stick
   - Download .ISO file from Microsoft's webpage
   - Create bootable USB using [WoeUSB](https://github.com/slacka/WoeUSB) - do not use Startup Disk Creator utility or the Disks app, won't work for Windows installation media)
1. Create Linux installation USB stick
   - Download .ISO file from the distribution's webpage
   - Create bootable USB using "whatever" (gnome disks or Startup Disk Creator utility)
1. Go to BIOS (F12) and switch from SSD's **RAID** mode to **AHCI** mode

## Fedora

- UEFI boot
- windows 10
- fedora 32 workstation

Automatic partitioning works right away

1. start the installation media
1. select the language and locale
1. select partitioning
   - select automatic partitioning
   - enable the "I want to recover some space" tickbox
   - enable the "I want to encrypt my data" tickbox
1. select the empty space or delete useless partitions; be sure to preserve Windows' partitions
1. select the timezone if needed
1. start the installation

## Ubuntu

- based on [`luispabon`'s gist][luispabon's gist], which is based on [`mdziekon`'s gist][mdziekon's gist]
- installation date: FIXME
- UEFI boot
- windows 10
- ubuntu 20.04

The process describes a completely fresh installation with complete repartitioning, however it should work fine when Windows is already installed (eg. brand new machine with Windows preinstalled) as long as Windows already boots with UEFI.

### Partitioning

1. Boot into an ubuntu live cd session
1. Open gparted
1. Delete all partitions on disk
1. Create GPT partition table: `device` > `new partition table` > choose `GPT` (this is required for EFI)
1. Create the following:
   1. 550MiB FAT32 (label EFI - label is for our own benefit, doesn't actually mark this partition as EFI)
   1. 550MiB EXT4 (for Linux boot)
   1. Create your windows partitions as NTFS
   1. Leave enough unallocated space for Ubuntu. Don't create a partition here yet - Windows needs to automatically create an additional 16MiB partition during installation. Dunno what it is for tbh.
1. Apply changes
1. Right click on the FAT32 partition you created for EFI partition above > `manage flags`. Set `esp` (`boot` might auto-check itself too). This will mark the partition to use as EFI by both Windows and Ubuntu installations. You might need to apply changes again.

### Install Windows

1. Boot from the windows usb pendrive
1. Install Windows on whatever partition you created earlier
1. Windows is done at this point - you could go in and setup windows (encryption, drivers, etc) but I'd recommend to set up ubuntu first - the process, if done wrong, can potentially bork your set up and you'll need to start again.

### Install Ubuntu

1. Boot into ubuntu live cd session
1. Open gparted, create a single ext4 partition with unallocated space. This will be for lvm/luks. The filesystem does not matter, we simply need to create a partition here so that it's allocated a device node and shows in `/dev`).
1. Create LUKS container on this partition (assuming the partition device is `/dev/nvme0n1p5`):
   - `sudo cryptsetup luksFormat /dev/nvme0n1p5` <-- `luksFormat` is case sensitive
   - `sudo cryptsetup luksOpen /dev/nvme0n1p5 cryptdrive` <-- `luksOpen` is case sensitive
   - `sudo dd if=/dev/zero of=/dev/mapper/cryptdrive bs=16M` <-- optional, this is to ensure nothing can be recovered from before this install you're doing. Took 2h on my 652 GiB partition.
1. Create LVM physical volume, a volume group & logical volumes:
   - Volumes are sized as follows (example, you should create as many partitions as you need):
     - OS drive: `60GB`
     - Swap: `16GB`
     - Home: `rest`
   - Commands (add extra lvcreate steps if you have more partitions):
     - `sudo pvcreate /dev/mapper/cryptdrive`
     - `sudo vgcreate vglinux /dev/mapper/cryptdrive`
     - `sudo lvcreate -n root -L 60g vglinux`
     - `sudo lvcreate -n swap -L 16g vglinux`
     - `sudo lvcreate -n home -l 100%FREE vglinux`
1. Start the installation process using GUI:
   - Connect to WiFi network
   - When asked what to do with the disk, pick the option that allows you to manually repartition stuff (IIRC it was labelled `Something else` on 19.04 installer):
     - Pick `/dev/mapper/vglinux-root` as `ext4` FS & mount it to `/`
     - Pick `/dev/mapper/vglinux-home` as `ext4` FS & mount it to `/home`
     - Pick `/dev/mapper/vglinux-swap` as `swap`
     - Do the same as above if you have extra partitions
     - Pick `/dev/nvme0n1p2` (created on step 2.5.1) as `ext4` FS & mount it to `/boot`
       - Without doing this, installation will fail when configuring GRUB
     - Pick "boot drive" (the select list at the bottom, this is where GRUB goes) and assign it to `/dev/nvme0n1p2` or `/dev/nvem0n1`
   - Proceed with the installation
1. After GUI installation completes, stay within the Live USB environment
1. Check the UUID of the LUKS drive:
   - `sudo blkid /dev/nvme0n1p5`
   - Example output: `/dev/nvme0n1p5: UUID="abcdefgh-1234-5678-9012-abcdefghijklm" TYPE="crypto_LUKS"`
1. Mount root & boot drives and chroot into the main mount:
   - `sudo mount /dev/mapper/vglinux-root /mnt`
   - `sudo mount /dev/nvme0n1p2 /mnt/boot`
   - `sudo mount --bind /dev /mnt/dev`
   - `sudo chroot /mnt`
   - `mount -t proc proc /proc`
   - `mount -t sysfs sys /sys`
   - `mount -t devpts devpts /dev/pts`
1. In chroot env, configure `crypttab` allowing to boot Ubuntu with Encryption unlocker
   - `sudo nano /etc/crypttab`:

     ```text
     # <target name> <source device> <key file> <options>
     # options used:
     #     luks    - specifies that this is a LUKS encrypted device
     #     tries=0 - allows to re-enter password unlimited number of times
     #     discard - allows SSD TRIM command, WARNING: potential security risk (more: "man crypttab")
     #     loud    - display all warnings
     cryptdrive UUID=abcdefgh-1234-5678-9012-abcdefghijklm none luks,tries=0,discard,loud
     ```

   - `update-initramfs -k all -c`
1. Reboot into Ubuntu

### Ubuntu Tweaks for XPS 9560

1. XPS 9560 doesn't really need any workarounds or acpi boot options anymore with Ubuntu 19.04. Have a look <https://github.com/stockmind/dell-xps-9560-ubuntu-respin> if there's something that doesn't work. No need to download any firmware anymore for the killer wifi (always worked fine for me)
1. Undervolt? <https://github.com/georgewhewell/undervolt> I have a systemd service to run `undervolt.py --core -125 --cache -125 --gpu -100`, helps a little with power consumption and temps, especially under heavy load (around 8-10 deg C).

### Reinstall Ubuntu

If you need to reinstall ubuntu, you should be able to jump to #4 directly. If you aren't changing your partition layout, you can go straight to #4.4 (install ubuntu), but don't forget to run `sudo cryptsetup luksOpen /dev/nvme0n1p5 cryptdrive` to mount the encrypted partition. If in doubt, just start from #4 and recreate your crypt drive.

### Additional notes

- Ubuntu (GRUB) is the default boot option, both Ubuntu and Windows should be there
- Additionally, you can bring up the UEFI boot screen pressing F12 as soon as you turn on the laptop

<!--
  References
  -->

<!-- Others -->
[luispabon's gist]: https://gist.github.com/luispabon/db2c9e5f6cc73bb37812a19a40e137bc
[mdziekon's gist]: https://gist.github.com/mdziekon/221bdb597cf32b46c50ffab96dbec08a
[ubuntu wiki community]: https://help.ubuntu.com/community/Full_Disk_Encryption_Howto_2019
