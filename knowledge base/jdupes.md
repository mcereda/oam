# Jdupes

## TL;DR

```sh
# prompt to delete all duplicate files
jdupes -Zdr directory

# automatically replace duplicate files with hard links to the first encountered
jdupes -ONLr directory1 directory2 directory3 file

# quickly list all duplicate gz archives
jdupes -rQX onlyext:gz directory

# delete all duplicates from a folder keeping all other folders intact
# will need multiple runs
find -mindepth 1 -maxdepth 1 -type d -not -name directoryWithDuplicates | xargs -I {} -n 1 -t jdupes -drINOZ {} directoryWithDuplicates
```

## Options

Short | Long                     | Description
------|--------------------------|------------
`-@`  | `--loud`                 | output annoying low-level debug info while running
`-B`  | `--dedupe`               | issue the btrfs _same-extents_ ioctl to trigger a deduplication on disk; jdupes **must be built with btrfs support** for this option to be available
`-D`  | `--debug`                | show debugging statistics and info at the end of program execution; the feature must be compiled in for this option to work
`-d`  | `--delete`               | prompt the user for files to preserve, deleting all others
`-I`  | `--isolate`              | isolate each command-line parameter from one another; only return a match if the files are under different parameters
`-L`  | `--link-hard`            | replace all duplicate files with hardlinks to the first file in each set of duplicates
`-m`  | `--summarize`            | summarize duplicate file information
`-M`  | `--print-summarize`      | print matches and summarize the duplicate file information at the end
`-N`  | `--no-prompt`            | when used together with `--delete`, preserve the first file in each set of duplicates and delete the others without prompting the user
`-O`  | `--param-order`          | parameter order preservation is more important than the chosen sort; this is particularly useful with the `-N` option to ensure that automatic deletion behaves in a controllable way
`-Q`  | `--quick`                | skip byte-for-byte verification of duplicate pairs (use hashes only)
`-q`  | `--quiet`                | hide progress indicator
`-r`  | `--recurse`              | for every directory given follow subdirectories encountered within
`-S`  | `--size`                 | show size of duplicate files
`-s`  | `--symlinks`             | follow symlinked directories
`-X`  | `--ext-filter=spec:info` | exclude/filter files based on specified criteria; see the [filter format](#filter-format) section
`-Z`  | `--soft-abort`           | if the user aborts the program (as with CTRL-C), act on the matches that were found before the abort was received; the default behavior without `-Z` is to abort without taking any actions


## Filter format

`jdupes -X filter[:value][size_suffix]`

Some filters take no value or multiple values.

Filters that can take a numeric option generally support the size multipliers `K`/`M`/`G`/`T`/`P`/`E`, with or without an added `iB` or `B`.  
Multipliers are binary-style unless the `-B` suffix is used, which will use decimal multipliers. For example, 16k or 16kib = 16384; 16kb = 16000. Multipliers are case-insensitive.

Filters have cumulative effects: `jdupes -X size+:99 -X size-:101` will cause only files of exactly 100 bytes in size to be included.

Extension matching is case-insensitive. Path substring matching is case-sensitive.

Supported filters:

- `size[+-=]:number[suffix]`: match only if size is greater (+), less than (-), or equal to (=) the specified number; the +/- and = specifiers can be combined, i.e. `size+=:4K` will only consider files with a size greater than or equal to 4 kilobytes (4096 bytes)
- `noext:ext1[,ext2,...]`: exclude files with certain extension(s), specified as a comma-separated list; do **not** use a leading dot
- `onlyext:ext1[,ext2,...]`: only include files with certain extension(s), specified as a comma-separated list; do not use a leading dot
- `nostr:text_string`: exclude all paths containing the substring *text_string*; this scans the full file path, so it can be used to match directories, i.e. `-X nostr:dir_name/`
- `onlystr:text_string`: require all paths to contain the substring *text_string*; this scans the full file path, so it can be used to match directories, i.e. `-X onlystr:dir_name/`
- `newer:datetime`: only include files newer than the specified date; use the date/time format _YYYY-MM-DD HH:MM:SS_; time is optional
- `older:datetime`: only include files older than the specified date; use the date/time format _YYYY-MM-DD HH:MM:SS_; time is optional

## Further readings

- Jdupes' [github] page

[github]: https://github.com/jbruchon/jdupes
