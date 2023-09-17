# Access Control Lists assignment

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Set default permissions for files and directories](#set-default-permissions-for-files-and-directories)
   1. [Posix](#posix)
   1. [NFSv4](#nfsv4)
1. [Further readings](#further-readings)

## TL;DR

When **setting** permissions, the _execute_ flag can be set to the **uppercase** `X` instead of the **lowercase** `x`.<br/>
The uppercase `X` permission allows execution only if the target is a directory or if the execute permission has already been set for the user or group.

BSD systems use NFSv4 ACLs by default in ZFS.
List of **NFSv4** [permission tags][syntax descriptions for setting acls] and [inheritance options][acl inheritance].

```sh
# Install the tool.
apt install 'acl'
dnf install 'acl'

# Show ACLs.
getfacl 'path/to/file'

# Set permissions for users.
setfacl -m 'u::r-x' 'path/to/file'
setfacl -m 'u::rwX' 'path/to/dir'
setfacl -m 'u:username:r-x' 'path/to/file'
setfacl -m 'u:username:rwX' 'path/to/dir'

# Add permissions for users.
# Position number starts from 0.
setfacl -a '1' 'u:username:rwx' 'path/to/file'
setfacl -a '2' 'u::rwX' 'path/to/dir'
setfacl -a '5' 'owner@:rw-p-daARWcCos::allow' 'path/to/file'
setfacl -a '6' 'owner@:rwxpDdaARWcCos::allow' 'path/to/dir'

# Set permissions for groups.
setfacl -m 'g::r-x' 'path/to/file'
setfacl -m 'g::rw-' 'path/to/dir'
setfacl -m 'g:username:r-x' 'path/to/file'
setfacl -m 'g:username:rwX' 'path/to/dir'

# Add permissions for groups.
# Position number starts from 0.
setfacl -a '2' 'g:groupname:r-x' 'path/to/file'
setfacl -a '4' 'g::rw-' 'path/to/dir'
setfacl -a '7' 'group@:r--p--aAR-c--s::allow' 'path/to/file'
setfacl -a '8' 'group@:r-xp--aAR-c--s::allow' 'path/to/dir'

# Add permissions for everyone else (others).
# Position number starts from 0.
setfacl -a '3' 'o::r-x' 'path/to/file'
setfacl -a '3' 'o::r-X' 'path/to/dir'
setfacl -a '9'  'everyone@:r-----a-R-c---::allow' 'path/to/file'
setfacl -a '10' 'everyone@:r-x---a-R-c---::allow' 'path/to/dir'

# Change multiple permissions in one command.
setfacl -m 'u::rw,g::r' 'path/to/file'
setfacl -m 'u::rwX,g::rwX,o::rx' 'path/to/dir'

# Make children files and directories inherit acls.
# A.K.A. set 'default' ACLs.
setfacl -dm 'u:dummy:rw' 'path/to/file'
setfacl -m 'default:u::rwX,g::rX,o:r' 'path/to/dir'
setfacl -a '11'    'group@:r-----a-R-c---:f------:allow' 'path/to/file'
setfacl -a '12' 'everyone@:r-x---a-R-c---:-d-----:allow' 'path/to/dir'

# Remove specific acls.
setfacl -x 'u:dummy:rw' 'test'

# Remove all ACL entries except for the ones synthesized from the file mode.
# If a 'mask' entry was in them, the resulting ACLs will be set accordingly.
setfacl -b 'path/to/file'
```

## Set default permissions for files and directories

Suppose you want a folder to set the default permissions of newly created files and directories to `0664` (`-rw-rw-r--`) and `0775` (`drwxrwxr-x`) respectively.<br/>
The best way to achieve this would be to set up it's ACLs accordingly.

### Posix

| Who   | ACL Type | Permissions          | Flags             | Translated `getfacl` Tags | Resulting Unix Permissions |
| ----- | -------- | -------------------- | ----------------- | ------------------------- | -------------------------- |
| user  | Allow    | Read, Write          | File Inherit      | `default:user::rw-`       | `-rw-------`               |
| user  | Allow    | Read, Write, Execute | Directory Inherit | `default:user::rwX`       | `drwx------`               |
| group | Allow    | Read, Write          | File Inherit      | `default:group::rw-`      | `----rw----`               |
| group | Allow    | Read, Write, Execute | Directory Inherit | `default:group::rwX`      | `d---rwx---`               |
| other | Allow    | Read, Write          | File Inherit      | `default:other::rw-`      | `-------rw-`               |
| other | Allow    | Read, Write, Execute | Directory Inherit | `default:other::rwX`      | `d------rwx`               |

```sh
setfacl -dm 'u::rwX' 'path/to/dir'
setfacl -dm 'g::rwX' 'path/to/dir'
setfacl -dm 'o::r-X' 'path/to/dir'

# Or, in one go.
setfacl -dm 'u::rwX,g::rwX,o::rX' 'path/to/dir'
```

### NFSv4

| Who       | ACL Type | Permissions                                                                                                                                                                                                             | Flags             | Translated `getfacl` Tags                | Resulting Unix Permissions |
| --------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ---------------------------------------- | -------------------------- |
| owner@    | Allow    | Read Data, Write Data, Append Data<br/>Read Named Attributes, Write Named Attributes<br/>Read Attributes, Write Attributes<br/>Delete<br/>Read ACL, Write ACL<br/>Write Owner<br/>Synchronize                           | File Inherit      | `   owner@:rw-p-daARWcCos:f------:allow` | `-rw-------`               |
| owner@    | Allow    | Read Data, Write Data, Append Data<br/>Read Named Attributes, Write Named Attributes<br/>Execute<br/>Read Attributes, Write Attributes<br/>Delete, Delete Child<br/>Read ACL, Write ACL<br/>Write Owner<br/>Synchronize | Directory Inherit | `   owner@:rwxpDdaARWcCos:-d-----:allow` | `drwx------`               |
| group@    | Allow    | Read Data, Write Data, Append Data<br/>Read Named Attributes, Write Named Attributes<br/>Read Attributes, Write Attributes<br/>Delete<br/>Read ACL, Write ACL<br/>Write Owner<br/>Synchronize                           | File Inherit      | `   group@:rw-p-daARWcCos:f------:allow` | `----rw----`               |
| group@    | Allow    | Read Data, Write Data, Append Data<br/>Read Named Attributes, Write Named Attributes<br/>Execute<br/>Read Attributes, Write Attributes<br/>Delete, Delete Child<br/>Read ACL, Write ACL<br/>Write Owner<br/>Synchronize | Directory Inherit | `   group@:rwxpDdaARWcCos:-d-----:allow` | `d---rwx---`               |
| everyone@ | Allow    | Read Data<br/>Read Named Attributes<br/>Read Attributes<br/>Read ACL                                                                                                                                                    | File Inherit      | `everyone@:r-----a-R-c---:f------:allow` | `-------r--`               |
| everyone@ | Allow    | Read Data<br/>Read Named Attributes<br/>Execute<br/>Read Attributes<br/>Read ACL                                                                                                                                        | Directory Inherit | `everyone@:r-x---a-R-c---:-d-----:allow` | `d------r-x`               |

```sh
setfacl -m        'owner@:rw-p-daARWcCos:f------:allow' 'path/to/dir'
setfacl -a '1'    'owner@:rwxpDdaARWcCos:-d-----:allow' 'path/to/dir'
setfacl -m        'group@:r--p--aAR-c--s:f------:allow' 'path/to/dir'
setfacl -a '3'    'group@:r-xp--aAR-c--s:-d-----:allow' 'path/to/dir'
setfacl -m     'everyone@:r-----a-R-c---:f------:allow' 'path/to/dir'
setfacl -a '5' 'everyone@:r-x---a-R-c---:-d-----:allow' 'path/to/dir'
```

## Further readings

- [Access Control Lists (ACL) in Linux]
- [`setfacl` FreeBSD manual page][setfacl freebsd manual page]
- [Syntax descriptions for setting ACLs]
- [ACL inheritance]

<!--
  References
  -->

<!-- Others -->
[access control lists (acl) in linux]: https://www.geeksforgeeks.org/access-control-listsacl-linux/
[acl inheritance]: https://docs.oracle.com/cd/E19253-01/819-5461/gbaax/index.html
[setfacl freebsd manual page]: https://man.freebsd.org/cgi/man.cgi?setfacl
[syntax descriptions for setting acls]: https://docs.oracle.com/cd/E19253-01/819-5461/gbaay/index.html
