# Pkgutil

Query and manipulate Mac OS X Installer packages and receipts.

`pkgutil` reads and manipulates Mac OS X Installer flat packages, and provides access to the "receipt" database used by the Installer.

Options are processed first, and affect the operation of all commands. Multiple commands are performed sequentially in the given order.

## TL;DR

```sh
# list the package id of all installed packages
pkgutil --pkgs
pkgutil --packages --volume /

# verify the cryptographic signature of a package
pkgutil --check-signature path/to/filename.pkg

# list all the files provided by an installed package given its id
pkgutil --files com.microsoft.Word

# extract the contents of a package into a directory
pkgutil --expand-full path/to/filename.pkg path/to/directory

# find what package provides a file
pkgutil --file-info Bitwarden.app/Contents/MacOS/Bitwarden
```

## Further readings

- [cheat.sh]

[cheat.sh]: https://cheat.sh/pkgutil
