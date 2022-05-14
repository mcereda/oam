# Access Control Lists assignment

## TL;DR

```sh
# show acls of file test/declarations.h
getfacl test/declarations.h

# set permissions for user awe-user
setfacl -m u:awe-user:rwx test/declarations.h

# set permissions for group awe-group
setfacl -m "g:awe-group:r-x" test/declarations.h

# make children files and directories inherit acls
# sets default acls
setfacl -d -m u:dummy:rw test

# remove a specific acl
setfacl -x u:dummy:rw test

# remove all acls
setfacl -b test/declarations.h
```

## Sources

- [Access Control Lists (ACL) in Linux]

[access control lists (acl) in linux]: https://www.geeksforgeeks.org/access-control-listsacl-linux/
