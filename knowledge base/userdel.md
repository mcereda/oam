# The `useradd` command

Delete users accounts and their related files.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Remove a user.
sudo userdel username

# Remove a user in other root directory.
sudo userdel --root path/to/other/root username

# Remove a user along with the home directory and mail spool.
sudo userdel --remove username
```

## Sources

- [cheat.sh]

<!--
  References
  -->

<!-- Others -->
[cheat.sh]: https://cheat.sh/userdel
