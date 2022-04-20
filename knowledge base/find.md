# Find

## TL;DR

```shell
# change the permissions of all files and directories in the current directory, recursively
find . -type d -exec chmod 755 {} +
find . -type f -exec chmod 644 {} +

# change the ownership of all files and directories owned by a specific user or group, recursively
find . -type d -user harry -exec chown daisy {} +
find . -type f -group users -exec chown :admin {} +

# delete all empty files and directories in the 'Documents' directory
find Documents -empty -delete               # recursively
find Documents -maxdepth 1 -empty -delete   # non recursively

# get the extensions of all files larger than 1MB
find . -type f -size +1M -exec basename {} \; | sed 's|.*\.||' | sort -u

# get all empty directories in a git repository (but not the repo's ones)
find $PATH_TO_REPO -type d -empty -not -path "./.git/*"

# find broken symlinks in the given directories, recursively
find $DIR1 $DIR2 $DIRN -type l -exec test ! -e {} ';' -print   # posix
find $DIR1 $DIR2 $DIRN -xtype l                                # gnu find only

# get files by name, in numeric order regardless of the directory they are in
find . -type f -o -type l \
  | awk 'BEGIN {FS="/"; OFS="|"} {print $NF,$0}' \
  | sort --field-separator '|' --numeric-sort \
  | cut -d '|' -f2

# print quoted file paths
# %p is for path
find . -type f -printf '%p\n'

# sort files by size
# %s is for size
find . -type f -printf '%s %p\n' | sort -nr | head -50

# get files which are executable but not readable
find /sbin /usr/sbin -executable -not -readable -print

# get files which are writable by either their owner or their group
find . -perm /220
find . -perm /u+w,g+w
find . -perm /u=w,g=w

# get files which are writable by both their owner and their group.
find . -perm -220
find . -perm -g+w,u+w

# list set-user-ID files and directories into /root/suid.txt and list large files into /root/big.txt
find / \( -perm -4000 -fprintf /root/suid.txt '%#m %u %p\n' \) , \( -size +100M -fprintf /root/big.txt '%-10s %p\n' \)
```

## Gotchas

- in GNU's `find` the path parameter defaults to the current directory and can be avoided

  ```shell
  # delete all empty folders in the current directory only
  find -maxdepth 1 -empty -delete
  ```

## Further readings

- [How can I find broken symlinks?]
- [find . -type f -exec chmod 644 {} ;]
- [how to output file names surrounded with quotes in SINGLE line?]

[find . -type f -exec chmod 644 {} ;]: https://stackoverflow.com/questions/19737525/find-type-f-exec-chmod-644#22083532
[how can i find broken symlinks?]: https://unix.stackexchange.com/questions/34248/how-can-i-find-broken-symlinks
[how to output file names surrounded with quotes in single line?]: https://stackoverflow.com/questions/6041596/how-to-output-file-names-surrounded-with-quotes-in-single-line#15137696
