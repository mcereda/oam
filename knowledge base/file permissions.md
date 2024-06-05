# File permissions

Core to the security model used by Linux systems.<br/>
They determine who can access files and directories on a system and how.

1. [TL;DR](#tldr)
1. [Representation](#representation)
1. [Advanced permissions](#advanced-permissions)
   1. [Set-user-ID (SUID)](#set-user-id-suid)
   1. [Set-group-ID (SGID)](#set-group-id-sgid)
   1. [Sticky Bit](#sticky-bit)
1. [Make files read-only](#make-files-read-only)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# View permissions.
ls -l 'path/to/file'

# Change permissions.
chmod u=rw,g+x,o-a 'path/to/file'
chmod 670 'path/to/file'
```

Directories need the execution permissions to be traversed.

## Representation

Permissions are part of the files' metadata:

```sh
$ ls -l
lrwxrwxrwx   1  me   me       31  Jan  2 22:09  gui_rpc_auth.cfg.standard -> /var/lib/boinc/gui_rpc_auth.cfg
drwxr-xr-x.  4  root root     68  Jun 13 20:25  tuned
-rw-r--r--.  1  user users  4017  Feb 24  2022  vimrc
```

The first character states the **type** of the file: `-` for files, `d` for directories, `l` for links and so on.

The next nine characters (e.g.: `rw-r--r--`) are 3 sets of 3 flags indicating the file's **permissions**.<br/>
Each of the 3 `rwx` characters in a set refers to the different operations (`r`ead, `w`rite and e`x`ecute) one can
perform on that file.<br/>
The first set shows the permissions for the user owning the file, the second is for the group, and the last is for
everyone and everything else.
Permissions can be expressed in both _symbolic_ (e.g., `u=rw`, `g=r`, `o=r`) and _numeric_ (octal, e.g., `644`)
representations.

The dot after the permissions shows whether the file has extended attributes.

The third column shows the **user** owning the file.

The fourth column shows the **group** owning the file.

## Advanced permissions

There are 3 special permissions apart from the usual `rwx` ones.<br/>
Those are `SUID`, `SGID`, and the `Sticky Bit`.

### Set-user-ID (SUID)

Files are executed by default with the privileges of the user who launched them.<br/>
If one sets the SUID bit on the executable, the file will always run with the privileges **of the owner** of the file.

> Only the owner of the file (or `root`) can set the SUID bit.

The SUID bit is set by:

- Replacing the `x` permissions of the user permissions set with an `s`:

  ```sh
  chmod 'u+s' 'vimrc'
  ```

- Using the octal representation prefixed by `4`:

  ```sh
  chmod '4744' 'vimrc'
  ```

When the SUID bit is set, the files show an `s` where there should be the `x` in the user's permissions set:

```sh
$ ls -l 'vimrc'
-rwsr--r--.  1  user users  4017  Feb 24  2022  vimrc
```

The SUID bit is unset by removing the `s` (`u-s`) or prefixing the octal notation with `0` instead of `4`.

### Set-group-ID (SGID)

Newly created files and directories are assigned by default the same group as the creator's default group.<br/>
When the SGID bit is set on directories, all **newly created** subdirectories and files under it will inherit the same group
ownership as of the directory itself.<br/>

SGID is useful in multi-user setups where users with different primary group have access to shared files.

When the SGID bit is set, the directories show an `s` where there should be the `x` in the group's permissions set:

```sh
$ ls -l 'tuned'
drwxr-sr-x.  4  root root     68  Jun 13 20:25  tuned
```

### Sticky Bit

If the sticky bit is set on directories, their subdirectories and files will only be deletable by either the owner of
the file, the owner of the parent directory, or `root`.

Useful to prevent users from deleting other users' files inside shared folders where everyone has write access.

The sticky bit is set by replacing the `x` permissions of the others permissions set with a `t`:

```sh
$ chmod 'o+t' 'vimrc'
$ ls -l
-rwsr--r-t.  1  user users  4017  Feb 24  2022  vimrc
```

## Make files read-only

Change files' attributes on Linux file systems using the `chattr` command:

```sh
# Make files read-only.
chattr +i '/path/to/file.php'
chattr +i '/var/www/html/'

# Find everything in '/var/www/html' and set it to read-only.
find '/var/www/html' -iname "*" -print0 | xargs -I {} -0 chattr +i {}

# Make files read-write.
chattr -i '/path/to/file.php'
```

FreeBSD, Mac OS X and other BSD unix user need to use the `chflags` command:

```sh
# Make files read-only.
chflags schg '/path/to/file.php'

# Make files read-write.
chflags noschg '/path/to/file.php'
```

## Further readings

- [`chmod`][chmod]
- [Access Control Lists][ACL]

### Sources

- [How to Set File Permissions in Linux]
- [Linux permissions: SUID, SGID, and sticky bit]
- [How to set readonly file permissions on Linux/Unix web server DocumentRoot]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[acl]: acl.md
[chmod]: chmod.md

<!-- Others -->
[how to set file permissions in linux]: https://www.geeksforgeeks.org/permissions-in-linux/
[linux permissions: suid, sgid, and sticky bit]: https://www.redhat.com/sysadmin/suid-sgid-sticky-bit
[how to set readonly file permissions on linux/unix web server documentroot]: https://www.cyberciti.biz/faq/howto-set-readonly-file-permission-in-linux-unix/
