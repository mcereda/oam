# Sudo

1. [TL;DR](#tldr)
1. [Drop privileges](#drop-privileges)
1. [Avoid the need of providing a password](#avoid-the-need-of-providing-a-password)
1. [Only allow specific commands](#only-allow-specific-commands)
1. [Execute commands as a specific user](#execute-commands-as-a-specific-user)
1. [Troubleshooting](#troubleshooting)
   1. [I modified a sudoers file manually, messed it up, and now I cannot use sudo anymore](#i-modified-a-sudoers-file-manually-messed-it-up-and-now-i-cannot-use-sudo-anymore)
1. [Sources](#sources)

## TL;DR

> Avoid modifying the `sudoers` files manually, and execute `visudo` instead.<br/>
> It will check the syntax on save, preventing you from screwing up the file.

Defaults:

| Path                     | Type               | OS       |
| ------------------------ | ------------------ | -------- |
| `/etc/sudoers`           | file               | All      |
| `/etc/sudoers.d`         | included directory | Linux    |
| `/private/etc/sudoers.d` | included directory | Mac OS X |

Sudoers files use the Extended Backus-Naur Form (EBNF) grammar.

Files in included directories are loaded in sorted lexical order.<br/>
Files which name ends in `~` or contains `.` are skipped to avoid causing problems with package manager or temporary or backup files.

When multiple entries match for the same user, they are applied in order.<br/>
Where there are multiple matches, the last match is used (which is not necessarily the most specific one).

```sh
# Make changes to a sudoers file.
visudo
visudo -f '/etc/sudoers.d/custom'

# Check the syntax of a sudoers file.
visudo -c
visudo -csf '/etc/sudoers.d/lana'
```

## Drop privileges

```sh
# Invalidate the user's cached credentials.
sudo -k

# Ignore the user's cached credentials for the given command only.
sudo -k ls
```

## Avoid the need of providing a password

```txt
# file '/etc/sudoers.d/adam'
adam ALL=(ALL:ALL) NOPASSWD: ALL
```

## Only allow specific commands

```txt
# file '/etc/sudoers.d/ginny'
Cmnd_Alias UPGRADE_CMND  = /usr/bin/apt update, /usr/bin/apt list --upgradable, /usr/bin/apt upgrade
Cmnd_Alias SHUTDOWN_CMND = /sbin/shutdown
ginny ALL=(ALL:ALL) SHUTDOWN_CMND, UPGRADE_CMND, ls
```

## Execute commands as a specific user

Invoke a login shell using the `-i, --login` option.<br/>
When not specifying a command, a login shell prompt is returned; otherwise, the output of the given command is returned:

```sh
% sudo -i -u 'johnny'
$ whoami
johnny

% sudo -i -u 'cynthia' whoami
cynthia
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
pkexec visudo -f '/etc/sudoers.d/michael'
```

## Sources

- [How to modify an invalid sudoers file]
- [sudo as another user with their environment]
- [sudo: drop root privileges]
- [Linux fundamentals: A to Z of a sudoers file]

<!--
  References
  -->

<!-- Others -->
[how to modify an invalid sudoers file]: https://askubuntu.com/questions/73864/how-to-modify-an-invalid-etc-sudoers-file
[linux fundamentals: a to z of a sudoers file]: https://medium.com/kernel-space/linux-fundamentals-a-to-z-of-a-sudoers-file-a5da99a30e7f
[sudo as another user with their environment]: https://unix.stackexchange.com/questions/176997/sudo-as-another-user-with-their-environment
[sudo: drop root privileges]: https://coderwall.com/p/x2oica/sudo-drop-root-privileges
