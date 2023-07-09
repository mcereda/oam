# Stunnel

Proxy designed to add TLS encryption functionality to existing clients and servers without any changes in the programs' code.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

In Unix-like operating systems:

```sh
# Install it.
brew install 'stunnel'

# Show default socket options.
stunnel -sockets

# Show supported TLS options.
stunnel -options

# Start the process.
stunnel 'path/to/config/file'
```

## Further readings

- [Website]
- [Sample configuration for Unix systems]

<!--
  References
  -->

<!-- Upstream -->
[sample configuration for unix systems]: https://www.stunnel.org/config_unix.html
[website]: https://www.stunnel.org/
