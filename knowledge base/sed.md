# SED

## TL;DR

```sh
# Delete lines matching "OAM" from a file.
# Overwrite the source file with the changes.
sed '/OAM/d' -i .bash_history

# Show changed fstab entries.
# Don't save the changes.
sed /etc/fstab \
  -e "s|#.*\s*/boot\s*.*|/dev/sda1  /boot  vfat   defaults             0 0|" \
  -e "s|#.*\s*ext4\s*.*|/dev/sda2  /      btrfs  compress-force=zstd  0 0|" \
  -e '/#.*\s*swap\s*.*/d'
```

## Further readings

- [GNU SED Online Tester]

[gnu sed online tester]: https://sed.js.org/
