# The `useradd` command

Delete users accounts and their related files.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Remove users.
sudo userdel 'username'

# Remove users from other (ch)root directories.
sudo userdel -R 'path/to/other/root' …
sudo userdel --root 'path/to/other/root' …

# Remove users along with their home directory and mail spool.
sudo userdel -r …
sudo userdel --remove …
```

## Sources

- [cheat.sh]

<!--
  References
  -->

<!-- Others -->
[cheat.sh]: https://cheat.sh/userdel
