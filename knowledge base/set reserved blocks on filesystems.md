# Set reserved blocks on filesystems

```sh
# EXT
tune2fs -m 1 /dev/sdXY
tune2fs -r numOfBlocks device

# XFS
xfs_io -x -c 'resblks' '/path/to/fs'
```

## Sources

- [Reserved space for root on a filesystem - why?]
- [How to determine the reserved blocks in XFS filesystem?]

<!--
  Reference
  ═╬═Time══
  -->

[how to determine the reserved blocks in xfs filesystem?]: https://lore.kernel.org/all/CAJtCNH2irjpu3T57XPHPXHZ0FXm7V-diaA4g3DtjAmcRV2xmWA@mail.gmail.com/T/
[reserved space for root on a filesystem - why?]: https://unix.stackexchange.com/questions/7950/reserved-space-for-root-on-a-filesystem-why
