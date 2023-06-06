# XDG base directory specification

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

| Environment variable | Type                                  | Description                                                                                                                                                                                                                                                                 | Default value                   |
| -------------------- | ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| `XDG_CONFIG_HOME`    | Single directory                      | User-specific configuration files                                                                                                                                                                                                                                           | `$HOME/.config`                 |
| `XDG_CACHE_HOME`     | Single directory                      | User-specific non-essential (cached) data                                                                                                                                                                                                                                   | `$HOME/.cache`                  |
| `XDG_DATA_HOME`      | Single directory                      | User-specific data files                                                                                                                                                                                                                                                    | `$HOME/.local/share`            |
| `XDG_STATE_HOME`     | Single directory                      | User-specific state data that should persist between application restarts, but not important or portable enough to be stored in `$XDG_DATA_HOME` like actions history (logs, history, recently used files, …) or current states (view, layout, open files, undo history, …) | `$HOME/.local/state`            |
|                      | Single directory                      | User-specific executable files, should be included in the UNIX `$PATH` environment variable at an appropriate place                                                                                                                                                         | `$HOME/.local/bin`              |
| `XDG_DATA_DIRS`      | Set of preference ordered directories | Search folders for data files in addition to the `$XDG_DATA_HOME` base directory; such directories should be separated with a colon (`:`)                                                                                                                                   | `/usr/local/share/:/usr/share/` |
| `XDG_CONFIG_DIRS`    | Set of preference ordered directories | Search folders for configuration files in addition to the `$XDG_CONFIG_HOME` base directory; such directories should be separated with a colon (`:`)                                                                                                                        | `/etc/xdg`                      |
| `XDG_RUNTIME_DIR`    | Single directory                      | User-specific non-essential runtime files and other file objects such as sockets, named pipes, …; the directory **must** live and die with the user's session, **must** be owned and accessible (`0700`) only by the user and **must** reside on the local disk             |                                 |

All paths set in these environment variables must be absolute. By specification, if an implementation encounters a relative path in any of these variables it should consider the path invalid and ignore it.

## Further readings

- [Specifications]

## Sources

- [Arch Linux Wiki page]

All the references in the [further readings] section, plus the following:

<!-- project's references -->
[specifications]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
<!-- external references -->
[arch linux wiki page]: https://wiki.archlinux.org/title/XDG_Base_Directory
