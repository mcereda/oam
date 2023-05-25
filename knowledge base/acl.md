# Access Control Lists assignment

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
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

## Sources

All the references in the [further readings] section, plus the following:

- [Access Control Lists (ACL) in Linux]

<!-- project's references -->
<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
<!-- external references -->
[access control lists (acl) in linux]: https://www.geeksforgeeks.org/access-control-listsacl-linux/
