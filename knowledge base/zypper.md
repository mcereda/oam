# The Zypper package manager

SUSE and openSUSE GNU/Linux's package management utility.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Gotchas](#gotchas)
1. [Further readings](#further-readings)

## TL;DR

```sh
# update the repositories
zypper refresh

# search for a package
zypper search nmap

# install a package
zypper install parallel
```

## Gotchas

Zypper does not have for now a way to list the content of an installed package. Use [rpm] for this:

```sh
sudo rpm --query --list ${PACKAGE_NAME}
```

## Further readings

- [rpm]
- [How can I list all files which have been installed by an ZYpp/Zypper package?]

<!--
  References
  -->

<!-- Knowledge base -->
[rpm]: rpm.md

<!-- Others -->
[how can i list all files which have been installed by an zypp/zypper package?]: https://unix.stackexchange.com/questions/162092/how-can-i-list-all-files-which-have-been-installed-by-an-zypp-zypper-package#239944
