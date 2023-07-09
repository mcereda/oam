# Dpkg

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Reconfigure packages.
dpkg-reconfigure --priority 'low' 'unattended-upgrades'

# Find which package provides a file already present on a system.
dpkg -S '/path/to/file'

# Find which files were installed by a package.
dpkg -L 'cfengine3'

# Find which files would be installed by a local package.
dpkg --contents 'cfengine3.deb'

# List available extra architectures.
dpkg-architecture --list-known

# Add extra architectures.
dpkg --add-architecture 'i386'

# List added extra architectures.
dpkg --print-foreign-architectures

# List all installed packages of the i386 architecture.
dpkg --get-selections | grep 'i386' | awk '{print $1}'

# Remove all traces of the i386 architecture.
apt-get purge \
  "$(dpkg --get-selections | grep --color=never 'i386' | awk '{print $1}')" \
&& dpkg --remove-architecture 'i386'
```

## Further readings

- [`apt`][apt]

## Sources

All the references in the [further readings] section, plus the following:

- [How to check if dpkg-architecture --list has all the architectures?]
- [List of files installed from apt package]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[apt]: apt.md

<!-- Others -->
[how to check if dpkg-architecture --list has all the architectures?]: https://askubuntu.com/questions/852115/how-to-check-if-dpkg-architecture-list-has-all-the-architectures#852120
[list of files installed from apt package]: https://serverfault.com/questions/96964/list-of-files-installed-from-apt-package#96965
