# The RPM package manager

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# List all installed packages.
rpm --query --all
rpm -qa

# List files installed by packages.
rpm --query --list 'package_name'
rpm -ql 'parallel'

# Find which package owns a file.
rpm --query --file '/path/to/file'
rpm -qf '/usr/bin/realm'

# List the contents of locally available RPM packages.
rpm --query --list --package 'path/to/file.rpm'
rpm -qlp 'downloads/foo.rpm'
```

## Further readings

- [How can I list all files which have been installed by an ZYpp/Zypper package?]

<!--
  References
  -->

<!-- Others -->
[how can i list all files which have been installed by an zypp/zypper package?]: https://unix.stackexchange.com/questions/162092/how-can-i-list-all-files-which-have-been-installed-by-an-zypp-zypper-package#239944
