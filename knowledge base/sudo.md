# Sudo

> Avoid modifying the `sudoers` files manually and execute `visudo` instead; it will check the syntax on save, preventing you from screwing up the file.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Drop privileges](#drop-privileges)
1. [Restrict permissions a little](#restrict-permissions-a-little)
1. [Avoid providing a password](#avoid-providing-a-password)
1. [Execute commands as a specific user](#execute-commands-as-a-specific-user)
1. [Troubleshooting](#troubleshooting)
   1. [I modified a sudoers file manually, messed it up, and now I cannot use sudo anymore](#i-modified-a-sudoers-file-manually-messed-it-up-and-now-i-cannot-use-sudo-anymore)
1. [Sources](#sources)

## TL;DR

```sh
# Make changes to a sudoers file.
visudo
visudo -f path/to/file

# Check the syntax of a sudoers file.
visudo -c path/to/file
```

## Drop privileges

```sh
# Invalidate the user's cached credentials.
sudo -k

# Ignore the user's cached credentials for the given command only.
sudo -k ls
```

## Restrict permissions a little

```sh
# file /etc/sudoers.d/user
Cmnd_Alias UPGRADE_CMND  = /usr/bin/apt update, /usr/bin/apt list --upgradable, /usr/bin/apt upgrade
Cmnd_Alias SHUTDOWN_CMND = /sbin/shutdown
user ALL=(ALL:ALL) NOPASSWD: SHUTDOWN_CMND, UPGRADE_CMND
```

## Avoid providing a password

```sh
# file /etc/sudoers.d/user
user ALL=(ALL:ALL) NOPASSWD: ALL
```

## Execute commands as a specific user

Invoke a login shell using the `-i, --login` option. When one does not specify a command a login shell prompt is returned, otherwise the output of the command is returned:

```sh
% whoami
root
% sudo -i -u user
$ whoami
user

% sudo -i -u user whoami
user
```

## Troubleshooting

### I modified a sudoers file manually, messed it up, and now I cannot use sudo anymore

Should you see something similar to this when using `sudo`:

```sh
$ sudo visudo
>>> /etc/sudoers: syntax error near line 28 <<<
sudo: parse error in /etc/sudoers near line 28
sudo: no valid sudoers sources found, quitting
```

try using another access method like `PolicyKit` and fix the file up:

```sh
pkexec visudo -f /etc/sudoers.d/user
```

## Sources

- [How to modify an invalid sudoers file]
- [sudo as another user with their environment]
- [sudo: Drop root privileges]

<!--
  References
  -->

<!-- Others -->
[how to modify an invalid sudoers file]: https://askubuntu.com/questions/73864/how-to-modify-an-invalid-etc-sudoers-file
[sudo as another user with their environment]: https://unix.stackexchange.com/questions/176997/sudo-as-another-user-with-their-environment
[sudo: drop root privileges]: https://coderwall.com/p/x2oica/sudo-drop-root-privileges
