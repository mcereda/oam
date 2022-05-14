# Mktemp

Creates a unique temporary file or directory and returns the absolute path to it.

## TL;DR

```sh
# create an empty temporary file
mktemp

# create an empty temporary directory
mktemp -d

# create an empty temporary file or directory with a random templated name
# the Xs must be put at the end of the filename
# the Xs specifies the templated parts and lenght in the file name
mktemp /tmp/filenameXXX
mktemp -d /tmp/dirname.XXX

# create an empty temporary file or directory with a specified suffix (GNU only)
mktemp --suffix ".txt"

# create an empty temporary file or directory with a specified prefix
mktemp -t "txt"
```

## Further readings

- [Man page]

[man page]: https://www.gnu.org/software/autogen/mktemp.html
