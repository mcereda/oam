# Pkexec

Allows _authorized_ users to execute commands as another user, similarly to [`sudo`][sudo].

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

If one does **not** specify a username, the command will be executed as `root`.

```sh
pkexec systemctl hibernate
```

## Further readings

- [Man page]
- [`sudo`][sudo]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[sudo]: sudo.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[man page]: https://linux.die.net/man/1/pkexec
