# Chmod

## TL;DR

```sh
# Change permissions of files or directories.
chmod '775' "path/to/dir"
chmod 'u=rw' "path/to/dir"
chmod 'go+x' "path/to/file"

# Set 'setuid' bit.
# Set on directories, forces new files to be owned by the same user by default.
chmod '04755' "path/to/dir"
chmod 'u-s' "path/to/file"

# Set 'setgid' bit.
# Set on directories, forces new files to be owned by the same group by default.
chmod '02775' "path/to/dir"
chmod 'g+s' "path/to/file"

# Set 'sticky' bit.
# Allows only the *owner* to change content and delete.
chmod '01775' "path/to/dir"
chmod 'a+t' "path/to/file"

# Set combinations of 'set*id' and 'sticky' bits.
chmod '03775' "path/to/setgid/and/sticky/dir"
chmod '05664' "path/to/setuid/and/sticky/file"
chmod '07644' "path/to/setuid/setgid/and/sticky/file"
```

## Sources

- [File permissions and attributes]

<!--
  References
  -->

<!-- Others -->
[file permissions and attributes]: https://wiki.archlinux.org/title/File_permissions_and_attributes
