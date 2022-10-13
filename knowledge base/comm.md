# comm

`comm` requires the files it is working with to be pre-sorted.

## TL;DR

```sh
# Print unique lines of file1 which are not present in file2.
comm -23 <(sort -u 'file1') <(sort -u 'file2')

# Check the whole content of file1 is present in file2.
[[ $(comm -23 <(sort -u 'file1') <(sort -u 'file2') | wc -l) -eq 0 ]]
```

## Sources

- [Check whether all lines of file occur in different file]

[check whether all lines of file occur in different file]: https://unix.stackexchange.com/questions/397747/check-whether-all-lines-of-file-occur-in-different-file#397749
