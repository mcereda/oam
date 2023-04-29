# Encrypted root filesystem

## Avoiding to type the passphrase twice

Add a key file to your initrd so that you only type the decryption passphrase in the bootloader.

This should only be done in an encrypted root partition that includes `/boot`, since having the initrd on an unencrypted `/boot` partition would defeat encrypting your root partition.

1. generate a new key

   ```sh
   sudo dd if=/dev/urandom of=/.root.key bs=1024 count=1
   ```

1. make the key file only readable by `root`:

   ```sh
   sudo chmod 600 /.root.key
   sudo chown root:root /.root.key
   ```

1. register the key file as a valid way to decrypt your root partition:

   ```sh
   sudo cryptsetup luksAddKey /dev/sda1 /.root.key
   ```

1. edit `/etc/crypttab` adding the key file to the third column of the row that pertains to the root partition by UUID:

   ```text
   cr_sda1 UUID=... /.root.key
   ```

1. add the key file to the initrd

   ```sh
   # suse
   echo -e 'install_items+=" /.root.key "' | sudo tee --append /etc/dracut.conf.d/99-root-key.conf > /dev/null
   ```

1. make `/boot` accessible to `root` only to prevent non-`root` users to read the initrd and extract the key file:

   ```sh
   sudo chmod 700 /boot
   ```

   to ensure that new permissions are not overwritten at a later timepoint, add the following line to `/etc/permissions.local`:

   ```text
   /boot/ root:root 700
   ```

If you have other encrypted partitions (e.g. `/home`, `swap`, etc), you can create additional keys to mount them without entering a passphrase.  
This works exactly as described above in steps 1-4, except that you don't need to add the key for those partitions to the initrd.

## Further readings

- [Avoiding to type the passphrase twice] on the [openSUSE wiki]
- [Encrypting an entire system] on the [Archlinux wiki]

[Avoiding to type the passphrase twice]: https://en.opensuse.org/SDB:Encrypted_root_file_system#Avoiding_to_type_the_passphrase_twice
[Encrypting an entire system]: https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system

[archlinux wiki]: https://wiki.archlinux.org
[openSUSE wiki]: https://en.opensuse.org/
