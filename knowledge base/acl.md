# Access Control Lists assignment

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Set default permissions for files and directories](#set-default-permissions-for-files-and-directories)
1. [Further readings](#further-readings)

## TL;DR

List of [permission tags][syntax descriptions for setting acls] and [inheritance options][acl inheritance].

```sh
# Install the tool.
apt install 'acl'
dnf install 'acl'

# Show ACLs.
getfacl 'test/declarations.h'

# Set permissions for users.
setfacl -m 'u:username:rwx' 'test/declarations.h'

# Add permissions for users.
# Position number starts from 0.
setfacl -a '1' 'u:username:rwx' 'test/declarations.h'
setfacl -a '5' 'owner@:rw-p-daARWcCos:f------:allow' 'path/to/file'
setfacl -a '6' 'owner@:rwxpDdaARWcCos:-d-----:allow' 'path/to/dir'

# Set permissions for groups.
setfacl -m "g:groupname:r-x" 'test/declarations.h'

# Add permissions for groups.
# Position number starts from 0.
setfacl -a '2' 'g:groupname:r-x' 'test/declarations.h'
setfacl -a '7' 'group@:r--p--aAR-c--s:f------:allow' 'path/to/file'
setfacl -a '8' 'group@:r-xp--aAR-c--s:-d-----:allow' 'path/to/dir'

# Add permissions for everyone else (others).
# Position number starts from 0.
setfacl -a '3' 'o::r-x' 'test/declarations.h'
setfacl -a '9'  'everyone@:r-----a-R-c---:f------:allow' 'path/to/file'
setfacl -a '10' 'everyone@:r-x---a-R-c---:-d-----:allow' 'path/to/dir'

# Make children files and directories inherit acls.
# A.K.A. sets default ACLs.
setfacl -d -m 'u:dummy:rw' 'test'

# Remove specific acls.
setfacl -x 'u:dummy:rw' 'test'

# Remove all ACL entries except for the ones synthesized from the file mode.
# If a 'mask' entry was in them, the resulting ACLs will be set accordingly.
setfacl -b 'test/declarations.h'
```

## Set default permissions for files and directories

Suppose you want a folder to set the default permissions of newly created files and directories to `0664` (`-rw-rw-r--`) and `0775` (`drwxrwxr-x`) respectively.

The best way to achieve this would be to set up it's ACLs accordingly:

| Who       | ACL Type | Permissions                                                                                                                                                                                                             | Flags             | Translated `getfacl` Tags                | Resulting Unix Permissions |
| --------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ---------------------------------------- | -------------------------- |
| owner@    | Allow    | Read Data, Write Data, Append Data<br/>Read Named Attributes, Write Named Attributes<br/>Read Attributes, Write Attributes<br/>Delete<br/>Read ACL, Write ACL<br/>Write Owner<br/>Synchronize                           | File Inherit      | `   owner@:rw-p-daARWcCos:f------:allow` | `-rw-------`               |
| owner@    | Allow    | Read Data, Write Data, Append Data<br/>Read Named Attributes, Write Named Attributes<br/>Execute<br/>Read Attributes, Write Attributes<br/>Delete, Delete Child<br/>Read ACL, Write ACL<br/>Write Owner<br/>Synchronize | Directory Inherit | `   owner@:rwxpDdaARWcCos:-d-----:allow` | `drwx------`               |
| group@    | Allow    | Read Data, Write Data, Append Data<br/>Read Named Attributes, Write Named Attributes<br/>Read Attributes, Write Attributes<br/>Delete<br/>Read ACL, Write ACL<br/>Write Owner<br/>Synchronize                           | File Inherit      | `   group@:rw-p-daARWcCos:f------:allow` | `----rw----`               |
| group@    | Allow    | Read Data, Write Data, Append Data<br/>Read Named Attributes, Write Named Attributes<br/>Execute<br/>Read Attributes, Write Attributes<br/>Delete, Delete Child<br/>Read ACL, Write ACL<br/>Write Owner<br/>Synchronize | Directory Inherit | `   group@:rwxpDdaARWcCos:-d-----:allow` | `d---rwx---`               |
| everyone@ | Allow    | Read Data<br/>Read Named Attributes<br/>Read Attributes<br/>Read ACL                                                                                                                                                    | File Inherit      | `everyone@:r-----a-R-c---:f------:allow` | `-------r--`               |
| everyone@ | Allow    | Read Data<br/>Read Named Attributes<br/>Execute<br/>Read Attributes<br/>Read ACL                                                                                                                                        | Directory Inherit | `everyone@:r-x---a-R-c---:-d-----:allow` | `d------r-x`               |

```sh
# Set default permissions of '0664' for files and '0775' for directories.
# Includes ACL-type permissions accordingly.
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
