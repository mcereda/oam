# Tar

## TL;DR

```sh
# create an archive
tar czvf directory.tar.gz directory
tar capvf archive.tar.bz2 directory1 directory2 file

# list the content of an archive
tar tf archive.tar
tar tf archive.tar member

# extract an archive
tar xpf archive.tar
tar xapf archive.tar.gz
tar xjpf archive.tar.bz2 file
```

## Interesting switches

short | long              | description
------|-------------------|--------------------------------------------------------------------------------------------------------
`-a`  | `--auto-compress` | use archive suffix to determine the compression program
`-c`  | `--create`        | create a new archive; directories are archived recursively, unless the `--no-recursion` option is given
`-C`  | `--directory DIR` | change to DIR before performing any operations; this option affects all options that follow
`-f`  | `--file FILE`     | use archive file or device FILE; if not given, tar will first examine the environment variable `TAPE` and default to the compiled-in default
`-r`  | `--append`        | append files to the end of an archive
`-t`  | `--list`          | list the contents of an archive; arguments are optional, but when given they specify the names of the members to list

## Further readings

- [how to compress and extract files using the tar command on linux]
- [how to create tar gz file in linux using command line]

[how to create tar gz file in linux using command line]: https://www.cyberciti.biz/faq/how-to-create-tar-gz-file-in-linux-using-command-line/
[how to compress and extract files using the tar command on linux]: https://www.howtogeek.com/248780/how-to-compress-and-extract-files-using-the-tar-command-on-linux/
