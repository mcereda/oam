# Mount samba shares from a unix client

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Mount samba shares as user 'myself'.
# Such user and a group of the same name exist on the server.
# Show permissions on directories as octal 775 and on files as octal 664.
sudo mount '//nas.lan/shared/folder' 'local/folder' -t 'cifs' \
  -o 'user=myself,uid=myself,gid=myself,dir_mode=0775,file_mode=0664' 
```

## Further readings

- [Mounting samba shares from a unix client]
- [`mount.cifs` man page][mount.cifs man page]

<!--
  References
  -->

<!-- Upstream -->
[mounting samba shares from a unix client]: https://wiki.samba.org/index.php/Mounting_samba_shares_from_a_unix_client

<!-- Others -->
[mount.cifs man page]: https://manpages.debian.org/testing/cifs-utils/mount.cifs.8.en.html
