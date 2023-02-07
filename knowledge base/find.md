# Find

## TL;DR

```sh
# Change the permissions of all files and directories in the current directory,
# recursively.
find . -type 'd' -exec chmod '755' {} +
find . -type 'f' -exec chmod '644' {} +

# Change the ownership of all files and directories owned by a specific user or
# group, recursively.
find . -type 'd' -user 'harry' -exec chown 'daisy' {} +
find . -type 'f' -group 'users' -exec chown ':admin' {} +

# Delete all empty files and directories in the 'Documents' directory.
find Documents -empty -delete               # recursively
find Documents -maxdepth '1' -empty -delete   # non recursively

# Get the extensions of all files larger than 1MB.
find . -type 'f' -size '+1M' -exec basename {} \; | sed 's|.*\.||' | sort -u

# Find all files between 5 and 10 MB.
find . -type 'f' -size '+5M' -size '-10M'

# Find files last accessed exactly 5 hour ago.
find . -type 'f' -amin '300'
find . -type 'f' -atime '5h'

# Find files last modified in the last hour.
find . -type 'f' -mmin '-60'
find . -type 'f' -mtime '-1h'

# Find files created more than 2 days ago.
find . -type 'f' -ctime '+2'

# Find all empty directories in a git repository that are not from git itself.
find 'path/to/repo' -type 'd' -empty -not -path "./.git/*"

# Find broken symlinks in the given directories, recursively.
find 'dir/1' 'dir/N' -type 'l' -exec test ! -e {} \; -print
find 'dir/1' 'dir/N' -xtype 'l'   # gnu find only

# Sort files by name, in numeric order, regardless of the directory they are in.
find . -type 'f' -o -type 'l' \
  | awk 'BEGIN {FS="/"; OFS="|"} {print $NF,$0}' \
  | sort --field-separator '|' --numeric-sort \
  | cut -d '|' -f2

# Print quoted file paths.
# %p is for path.
find . -type 'f' -printf '"%p"\n'
find . -type 'f' -printf "'%p'\n"

# Sort files by size.
# %s is for size, %p is for path.
find . -type 'f' -printf '%s %p\n' | sort -nr | head -50

# Find files which are executable but not readable.
find '/sbin' '/usr/sbin' -executable -not -readable -print

# Find files which are writable by either their owner or their group.
find . -perm '/220'
find . -perm '/u+w,g+w'
find . -perm '/u=w,g=w'

# Find files which are writable by both their owner and their group.
find . -perm '-220'
find . -perm '-g+w,u+w'

# Record set-user-ID files and directories into '/root/suid.txt', and large
# files into 'big-files.txt'
find / \
  \( -perm '-4000' -fprintf '/root/suid.txt' '%#m %u %p\n' \) , \
  \( -size '+100M' -fprintf 'big-files.txt' '%-10s %p\n' \)

# Show files with hard links.
find . -type 'f' -not -links '1'
find -type 'f' -links '+1'

# Show files hard linked to a given file.
# GNU extension.
find -samefile 'path/to/file'
```

## Time specifications

Primaries used to check the difference between the file last access, creation or modification time and the time `find` was started.

All time specification primaries take a numeric argument, and allow the number to be preceded by a plus sign (`+`) or a minus sign (`-`).  
A preceding plus sign means **more than `n`**, a preceding minus sign means **less than `n`** and neither means **exactly `n`**.

Accepted time information:

- `a` for the file's last access time
- `c` for the time of last change of file status information (creation)
- `m` for the file's last modification time
- `B` for the file's inode creation time

With the `-Xmin` form, times are rounded up to the next full **minute**. This is the same as using `-Xtime Nm`.

With the `-Xtime` form, times depend on the given unit; if no unit is given, it defaults to full 24 hours periods (days).  
Accepted units:

- `s` for seconds
- `m` for minutes (60 seconds)
- `h` for hours (60 minutes)
- `d` for days (24 hours)
- `w` for weeks (7 days)

Any number of units may be combined in one `-Xtime` argument.

with the `-newerXY file` form, `find` checks if `file` has a more recent last access time (X=a), inode creation time (X=B), change time (X=c), or modification time (X=m) than the last access time (Y=a), inode creation time (Y=B), change time (Y=c), or modification time (Y=m).  
If Y=t, `file` is interpreted as a direct date specification of the form understood by `cvs`. Also, `-newermm` is the same as `-newer`.

```sh
# Find files last accessed exactly 5 minutes ago.
find /dir -amin 5
find /dir -atime 300s
find /dir -atime 5m

# Find files last accessed in the last 3 days.
find /dir -atime -3
find /dir -atime -3d

# Find files created in the last 1.5 hour.
find /dir -cmin -90
find /dir -ctime -1h30m

# Find files created more than 4 days ago.
find /dir -ctime +4

# Find files modified less than 30 minutes ago.
find /dir -mmin -30
find /dir -mtime -30m
find /dir -mtime -.5h   # gnu find only

# Find files modified exactly 2 days ago.
find /dir -mtime 2
find /dir -mtime 48h

# Find files modified more than 4 weeks ago.
find /dir -mtime +28
find /dir -mtime +4w

# Find all files whose inode change time is more recent than the current time
# minus one minute.
find / -newerct '1 minute ago'

# Find files owned by 'wnj' that are newer than 'file.txt'.
find / -newer file.txt -user wnj -print
```

## Gotchas

- in GNU's `find` the path parameter defaults to the current directory and can be avoided

  ```sh
  # Delete all empty folders in the current directory only.
  find -maxdepth 1 -empty -delete
  ```

- GNU's `find` also understands fractional time specifications:

  ```sh
  # Find files modified in the last 1 hour and 30 minutes.
  find -mtime 1.5h
  ```

## Sources

- [How can I find broken symlinks?]
- [find . -type f -exec chmod 644 {} ;]
- [How to output file names surrounded with quotes in SINGLE line?]
- [How to find all hardlinks in a folder?]

[find . -type f -exec chmod 644 {} ;]: https://stackoverflow.com/questions/19737525/find-type-f-exec-chmod-644#22083532
[how can i find broken symlinks?]: https://unix.stackexchange.com/questions/34248/how-can-i-find-broken-symlinks
[how to find all hardlinks in a folder?]: https://askubuntu.com/questions/972121/how-to-find-all-hardlinks-in-a-folder#972244
[how to output file names surrounded with quotes in single line?]: https://stackoverflow.com/questions/6041596/how-to-output-file-names-surrounded-with-quotes-in-single-line#15137696
