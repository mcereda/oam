# Cryptsetup

## TL;DR

```sh
# crypt a device
sudo cryptsetup luksFormat /dev/sdb
sudo cryptsetup luksOpen /dev/sdb crypted-device
sudo mkfs.btrfs --label data /dev/mapper/crypted-device
sudo mount --types btrfs --options compress-force=zstd:3 /dev/mapper/crypted-device /media/data
sudo umount /media/data
sudo cryptsetup luksClose /dev/mapper/crypted-device
```

## Crypt a device

1. create the luks partition

   ```sh
   sudo cryptsetup luksFormat /dev/sdb
   ```

   as of cryptsetup version 2.3.4, this is equivalent to

   ```sh
   cryptsetup --type luks2 --cipher aes-xts-plain64 --hash sha256 --iter-time 2000 --key-size 256 --pbkdf argon2i --sector-size 512 --use-urandom --verify-passphrase luksFormat device
   ```

1. open the luks partition

   ```sh
   sudo cryptsetup luksOpen /dev/sdb samsung_860_evo_1tb
   ```

1. format the partition

   ```sh
   sudo mkfs.btrfs --label samsung_860_evo_1tb /dev/mapper/samsung_860_evo_1tb
   ```

1. mount the partition

   ```sh
   sudo mount --types btrfs --options compress-force=zstd:0,nodev,nosuid,uhelper=udisks2 /dev/mapper/samsung_860_evo_1tb /mnt/samsung_860_evo_1tb
   ```

1. do what you need
1. umount the partition

   ```sh
   sudo umount /mnt/samsung_860_evo_1tb
   ```

1. close the luks partition

   ```sh
   sudo cryptsetup luksFormat /dev/sdb
   ```

## Troubleshooting

### The process is killed due to too much memory used

Should you get the following result during any operation:

```sh
$ sudo cryptsetup luksOpen /dev/sdb1 crypted-data
Enter passphrase for /dev/sdb1: ***
killed
```

it could be the process is using too much memory.  
This is due to the LUKS2 format using by default the Argon2i key derivation function, that is so called _memory-hard function_ - it requires certain amount of physical memory (to make dictionary attacks more costly).

The solution is simple; either:

1. switch to LUKS1, or
2. use LUKS2, but switch to PBKDF2 (the one used in LUKS1); just add the `--pbkdf pbkdf2` option to luksFormat or to any command that creates keyslots, or
3. use LUKS2 but limit the memory assigned to Argon2i function; for example, to use up to 256kB just add the `--pbkdf-memory 256` option to the command as follows:

   ```sh
   $ sudo cryptsetup luksOpen --pbkdf-memory 256 /dev/sdb1 lacie
   Enter passphrase for /dev/sda1: ***
   ```

## Further readings

- [arch linux wiki]
- [btrfs man page]
- [High memory usage when opening a LUKS2 partition]

[arch linux wiki]: https://wiki.archlinux.org/index.php/dm-crypt/Device_encryption
[btrfs man page]: https://btrfs.wiki.kernel.org/index.php/Manpage/btrfs(5)
[high memory usage when opening a luks2 partition]: https://gitlab.com/cryptsetup/cryptsetup/issues/372
