# Tar

1. [TL;DR](#tldr)
1. [Options of interest](#options-of-interest)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Create archives.
tar czvf 'directory.tar.gz' 'source-directory'
tar -capvf 'archive.tar.bz2' 'directory1' 'directory2' 'file1' 'fileN'

# List the content of archives.
tar tf 'archive.tar'
tar -tf 'archive.tar' 'file-in-archive'

# Test archives by reading their contents or extracting them to stdout.
tar tf 'archive.tar' > '/dev/null'
tar tOf 'archive.tar' > '/dev/null'

# Extract archives.
tar xpf 'archive.tar'
tar xapf 'archive.tar.gz'
tar -xjpOf 'archive.tar.bz2' 'file-in-archive'
```

## Options of interest

| Short | Long              | Description                                                                                                                                  |
| ----- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `-a`  | `--auto-compress` | use archive suffix to determine the compression program                                                                                      |
| `-c`  | `--create`        | create a new archive; directories are archived recursively, unless the `--no-recursion` option is given                                      |
| `-C`  | `--directory DIR` | change to DIR before performing any operations; this option affects all options that follow                                                  |
| `-f`  | `--file FILE`     | use archive file or device FILE; if not given, tar will first examine the environment variable `TAPE` and default to the compiled-in default |
| `-r`  | `--append`        | append files to the end of an archive                                                                                                        |
| `-t`  | `--list`          | list the contents of an archive; arguments are optional, but when given they specify the names of the members to list                        |

## Further readings

### Sources

- [How to compress and extract files using the tar command on linux]
- [How to create tar gz file in linux using command line]
- [How to test tar file integrity]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Others -->
[how to create tar gz file in linux using command line]: https://www.cyberciti.biz/faq/how-to-create-tar-gz-file-in-linux-using-command-line/
[how to compress and extract files using the tar command on linux]: https://www.howtogeek.com/248780/how-to-compress-and-extract-files-using-the-tar-command-on-linux/
[how to test tar file integrity]: https://www.baeldung.com/linux/tar-integrity-check
