# The RPM package manager

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# list all installed packages
rpm --query --all

# list files installed by a package
rpm --query --list package

# find the package owning a file
rpm --query --file /usr/bin/file
```

## Further readings

- [How can I list all files which have been installed by an ZYpp/Zypper package?]

<!--
  References
  -->

<!-- Others -->
[how can i list all files which have been installed by an zypp/zypper package?]: https://unix.stackexchange.com/questions/162092/how-can-i-list-all-files-which-have-been-installed-by-an-zypp-zypper-package#239944
