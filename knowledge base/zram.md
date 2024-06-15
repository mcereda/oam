# ZRAM

TODO

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
$ grep 'swap' /etc/fstab
/dev/zram0                none       swap sw                0 0

$ cat /etc/modules-load.d/zram.conf
zram

# Create a zram block device with total capacity of 2x the total RAM.
# Size is determined by the 'echo ...' part.
$ cat /etc/udev/rules.d/10-zram.rules
KERNEL=="zram0", \
SUBSYSTEM=="block", \
ACTION=="add", \
ATTR{initstate}=="0", \
PROGRAM="/bin/sh -c 'echo $(($(LANG=C free --kilo | sed --silent --regexp-extended s/^Mem:\ (0-9+)\ +.$/\1/p)*2))KiB'", \
ATTR{disksize}="$result", \
RUN+="/sbin/mkswap $env{DEVNAME}", \
TAG+="systemd"
```

## Further readings

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
