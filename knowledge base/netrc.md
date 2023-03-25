# The `.netrc` file

Specifies automatic login information for the `ftp` and `rexec` commands.

It is located under a user's home directory (`~/.netrc`) and must be owned
either by the user executing the command or by the root user.
If the .netrc file contains a login password, the file's permissions must be set
to `600` (read and write by its owner only).

## Format

The file can contain the following entries separated by spaces, tabs, or new
lines:

- `machine` _hostname_: this begins the definition of the automatic login
  process for the specified _hostname_; all the following entries, up to a new
  `machine` entry or the end of the file, will apply to _hostname_
- `default`: like `machine`, but matches any hostname; there can be only 1 in
  the whole file and it is considered the last entry (entries following it will
  be ignored)
- `login` _username_: the full domain user name used for authentication; if
  found the automatic login process initiates a login with the specified
  _username_, else it will fail
- `password` _password_: the password to use for authentication; it must be
  set at the remote host and must be present in `.netrc`, otherwise the process
  will fail and the user is prompted for a new value
  > passwords in this fields cannot contain spaces

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

[netrc]: https://everything.curl.dev/usingcurl/netrc
