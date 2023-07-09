# Sponge

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# installation
brew install sponge   # or moreutils

# append file content to the source file
cat path/to/file | sponge -a path/to/other/file

# remove all lines starting with "#" in a file
grep -v '^{{#}}' path/to/file | sponge path/to/other/file
```

## Further readings

- [mankier man page]
- [tldr live demo page]

<!--
  References
  -->

<!-- Others -->
[mankier man page]: https://www.mankier.com/1/sponge
[tldr live demo page]: https://tldr.ostera.io/sponge
