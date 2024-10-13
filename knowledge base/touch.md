# The `touch` command

1. [TL;DR](#tldr)

## TL;DR

```sh
# Change the access and modification date of files.
# End the time with 'Z' to specify the new time is UTC instead of local time.
touch -cd '2017-08-15T13:28:42' '20170815_132842.mp4'
touch -cd '2017-08-15T12:28:42Z' '20170815_132842.mp4'

# Change only the access time.
touch -ca -t '201801211200.10' 'file.txt'
touch -c --time=access -t '201801211200.10' 'file.txt'
touch -c --time=atime -d '2018-01-21T12:00:10' 'file.txt'

# Change only the modification time.
touch -cm -t '201611161200.10' 'file.txt'
touch -c --time=modify -t '201611161200.10' 'file.txt'
touch -c --time=mtime -d '2016-11-16T12:00:10' 'file.txt'
```
