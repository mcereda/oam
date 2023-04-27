# Helios4

## Table of contents <!-- omit in toc -->

1. [TL:DR](#tldr)
1. [OS installation](#os-installation)
1. [First boot](#first-boot)
1. [Connect to the Helios4 using a serial console](#connect-to-the-helios4-using-a-serial-console)
   1. [First login](#first-login)
1. [Configuration](#configuration)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL:DR

## OS installation

See the official [installation guide] for details.

Requirements:

1. MicroSD card, possibly UHS-I or greater with 8GB free.<br/>
   Suggested models:
   
   - SanDisk Extreme microSDHC UHS-I (32GB)
   - SanDisk Extreme PRO microSDHC UHS-I (32GB)
   - Strontium Nitro MicroSD (16GB)
   - Samsung microSDHC UHS-I EVO Plus (32GB)

   Refer to the [SD Card page][tested microsd cards] for a compatibility list of SD Card models.

1. USB to microUSB cable.
1. Ethernet cable category 5 or higher.

Procedure:

1. Download the ISO from the [download page].
1. Copy the ISO to the SD card and make it bootable:
   
   - using [balenaetcher];
   - using the CLI:

     ```sh
     zcat 'Armbian_20.05.2_Helios4_buster_current_5.4.43.img.gz' \
     | pv \
     | sudo dd of='/dev/mmcblk0' bs='1M' conv='fsync'
     ```

## First boot

Connect the device in order:

1. inserted the microSD card;
1. connect your computer to the serial port with the Micro-USB to USB cable;
1. connect the device to the network with the Ethernet cable;
1. properly plug in the DC power connector before plugging the AC adapter into the wall.

Now, connect the power adapter.

## Connect to the Helios4 using a serial console

```sh
brew install 'picocom'
sudo apt install 'picocom'
sudo yum install 'picocom'

sudo picocom -b '115200' '/dev/ttyUSB0'

# Alternatively.
screen '/dev/tty.usbserial-XXXXXXXX' '115200' -L
```

### First login

Username: `root`
Password: `1234`

## Configuration

```sh
sudo armbian-config
```

## Further readings

- [Armbian]

## Sources

All the references in the [further readings] section, plus the following:

<!-- project's references -->
[download page]: https://wiki.kobol.io/download/#helios4
[installation guide]: https://wiki.kobol.io/helios4/install/
[tested microsd cards]: https://wiki.kobol.io/helios4/sdcard/#tested-microsd-card

<!-- internal references -->
[armbian]: armbian.md
[further readings]: #further-readings

<!-- external references -->
[balenaetcher]: http://etcher.io/
