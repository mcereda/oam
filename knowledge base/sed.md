# SED

## TL;DR

```shell
# Delete lines matching "OAM" from a file.
sed -e '/OAM/d' -i .bash_history

# Change fstab entries.
sed /etc/fstab \
  -e "s|#.*\s*/boot\s*.*|/dev/sda1  /boot  vfat   defaults             0 0|" \
  -e "s|#.*\s*ext4\s*.*|/dev/sda2  /      btrfs  compress-force=zstd  0 0|" \
  -e '/#.*\s*swap\s*.*/d'
```
