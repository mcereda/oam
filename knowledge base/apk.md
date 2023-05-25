# APK

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Update the package lists.
apk update

# Search for packages
apk search 'duperemove'
apk search -a 'parallel'
apk --no-cache search -v

# Get information about packages.
apk info 'htop'
apk --no-cache info -a 'curl'

# List installed packages.
apk list -I

# Install packages.
apk add 'zstd'
apk --no-cache add -i 'zfs=2.1.4-r0' 'xz>=5.2.0'
apk -s add --allow-untrusted 'path/to/foo.apk'

# Upgrade packages.
apk upgrade
apk --no-cache add -iu 'apk-tools'
apk -s add -u --allow-untrusted 'path/to/foo.apk'

# Remove packages.
apk del 'php7'

# Remove cache.
apk cache clean
apk cache -v sync

# Find what package provides a file.
apk info --who-owns '/etc/passwd'

# List files included in a package.
apk info -L 'zsh'

# Check if a package is installed.
apk info -e 'fdupes'

# List packages dependencies.
apk info -R 'atop'

# List packages depending on a package.
apk info -r 'bash'

# Show the installed size of an installed package.
apk info -s 'top'

# Get an installed package's description.
apk info -d 'parallel'
```

## Sources

- [10 Alpine Linux apk Command Examples]

<!-- project's references -->
<!-- in-article references -->
<!-- internal references -->
<!-- external references -->
[10 alpine linux apk command examples]: https://www.cyberciti.biz/faq/10-alpine-linux-apk-command-examples/
