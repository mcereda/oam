# Authenticate without using sudo

## Table of contents <!-- omit in toc -->

1. [Polkit](#polkit)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Polkit

Requires [`polkit`][polkit] to be:

- installed
- configured to authorize and authenticate the users

```sh
pkexec COMMAND
```

## Further readings

- [`pkexec`][pkexec]

## Sources

All the references in the [further readings] section, plus the following:

- [How to get gui sudo password prompt without command line]

<!--
  References
  -->

<!-- Knowledge base -->
[pkexec]: pkexec.md
[polkit]: polkit.md

<!-- Others -->
[how to get gui sudo password prompt without command line]: https://askubuntu.com/questions/515292/how-to-get-gui-sudo-password-prompt-without-command-line
