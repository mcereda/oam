# Sync

```sh
# Flush all cached file data of the current user only.
sync

# Flush all pending write operations on all disks and mounted file systems.
sudo sync

# Flush all pending write operations on given files only to disk.
sync path/to/first/file path/to/second/file

# Flush all pending write operations on all files in a directory, recursively.
sync path/to/directory

# Flush only the file data and its minimal metadata to disk.
sync -d path/to/file

# Flush all pending write operations on only the filesystem on mounted partition
# '/dev/sdc1'.
sudo sync /dev/sdc1

# Flush all pending write operations on all mounted filesystem from '/dev/sdb'.
sudo sync /dev/sdb

# Flush all pending write operations on the entire file system which contains
# '/var/log/syslog'.
sudo sync -f /var/log/syslog
```

## Sources

- [cheat.sh]
- [Linux sync command]

[cheat.sh]: https://cheat.sh/sync
[linux sync command]: https://www.computerhope.com/unix/sync.htm
