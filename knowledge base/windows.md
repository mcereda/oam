# Microsoft Windows

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Disable fast startup on Windows 10](#disable-fast-startup-on-windows-10)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```bat
Rem Check ports in listening state.
netstat -an
```

```ps1
# Test a network connection.
Test-NetConnection -Port 443 -ComputerName 192.168.0.1 -InformationLevel Detailed
```

## Disable fast startup on Windows 10

1. open the Control Panel
1. choose on _Power Options_
1. choose _Choose what the power buttons do_
1. choose _Change settings that are currently unavailable_ to make the setting editable
1. deselect _Turn on fast startup (recommended)_
1. save the changes

## Further readings

- [WinGet]

[winget]: winget.md

## Sources

- [How to disable Windows 10 fast startup (and why you'd want to)]

<!--
  References
  -->

<!-- Others -->
[how to disable windows 10 fast startup (and why you'd want to)]: https://www.windowscentral.com/how-disable-windows-10-fast-startup
