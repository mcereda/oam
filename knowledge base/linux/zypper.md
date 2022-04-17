# The Zypper package manager

SUSE and openSUSE GNU/Linux's package management utility.

## TL;DR

```shell
# update the repositories
zypper refresh

# search for a package
zypper search nmap

# install a package
zypper install parallel
```

## Gotchas

Zypper does not have for now a way to list the content of an installed package. Use [rpm] for this:

```shell
sudo rpm --query --list ${PACKAGE_NAME}
```

## Further readings

- [rpm]

[rpm]: rpm.md

## Sources

- [How can I list all files which have been installed by an ZYpp/Zypper package?]

[how can i list all files which have been installed by an zypp/zypper package?]: https://unix.stackexchange.com/questions/162092/how-can-i-list-all-files-which-have-been-installed-by-an-zypp-zypper-package#239944
