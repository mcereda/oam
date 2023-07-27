# Access Control Lists assignment

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Install the tool.
apt install 'acl'
dnf install 'acl'

# Show acls of files.
getfacl 'test/declarations.h'

# Set permissions for users.
setfacl -m 'u:username:rwx' 'test/declarations.h'

# Set permissions for groups.
setfacl -m "g:groupname:r-x" 'test/declarations.h'

# Make children files and directories inherit acls.
# A.K.A. sets default acls.
setfacl -d -m 'u:dummy:rw' 'test'

# Remove specific acls.
setfacl -x 'u:dummy:rw' 'test'

# Remove all acls.
setfacl -b 'test/declarations.h'
```

## Further readings

- [Access Control Lists (ACL) in Linux]

<!--
  References
  -->

<!-- Others -->
[access control lists (acl) in linux]: https://www.geeksforgeeks.org/access-control-listsacl-linux/
