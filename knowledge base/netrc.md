# The `.netrc` file

Specifies automatic login information for the `ftp` and `rexec` commands.

1. [TL;DR](#tldr)
1. [Format](#format)
1. [Further readings](#further-readings)

## TL;DR

Located under a user's home directory (`~/.netrc`).<br/>
It **must** be owned by either the user executing the command, or by the `root` user.<br/>

If a `.netrc` file contains a login password, the file's permissions **must** be set to `600` (read and write for its
owner only).

## Format

The file can contain the following entries separated by spaces, tabs, or new lines:

- `machine` _hostname_: starts the definition of the automatic login process for the specified _hostname_.<br/>
  All entries following this key, up to a new `machine` entry or the end of the file, will apply to just the specified
  _hostname_.
- `default`: works like `machine`, but matches **any** hostname.<br/>
  There can be only 1 in the whole file, and it must the last entry. Entries following this key will be ignored.
- `login` _username_: the full user name used for authentication; if found, the automatic login process initiates a
  login with the specified _username_, otherwise it will fail.
- `password` _password_: the password to use for authentication.<br/>
  It **must** be set at the remote host, and must be present in `.netrc`. Otherwise, the process will fail and the user
  will be prompted for a new value.

  > [!warning]
  > Passwords in this fields **cannot** contain spaces.

The two formats below are equivalent:

```txt
machine example.com login daniel password qwerty
machine host1.austin.century.com login fred password bluebonnet
```

```txt
machine example.com
login daniel
password qwerty
machine host1.austin.century.com
login fred
password bluebonnet
```

## Further readings

- [netrc]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Others -->
[netrc]: https://everything.curl.dev/usingcurl/netrc
