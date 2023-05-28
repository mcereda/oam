# Sort

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sort by the value in the last field](#sort-by-the-value-in-the-last-field)
1. [Sources](#sources)

## TL;DR

```sh
# Sort given lines.
sort 'path/to/file'

# Sort lines in reverse.
sort -r 'path/to/file'

# Sort lines numerically.
sort -n 'path/to/file'

# Sort lines and remove duplicates.
sort -u 'path/to/file'

# Sort lines in random order.
sort -R 'path/to/file'

# Sort lines numerically according to the value in the 3rd column.
sort -t $'\t' -k 3n,3 'path/to/file'

# Sort by the value in the last field.
awk 'BEGIN {FS=","; OFS="|"} {print $NF,$0}' file.txt \
| sort -n -t '|' | awk -F '|' '{print $NF}'
```

## Sort by the value in the last field

1. copy the last field (column) of each line at the beginning of each of the lines with a different delimiter:

   ```sh
   awk 'BEGIN {FS=","; OFS="|"} {print $NF,$0}' file.txt
   ```

1. sort on the 1st field specifing the delimiter to be the character above:

   ```sh
   awk 'BEGIN {FS=","; OFS="|"} {print $NF,$0}' file.txt | sort -n -t '|'
   ```

1. discard the first field

   ```sh
   awk 'BEGIN {FS=","; OFS="|"} {print $NF,$0}' file.txt | sort -n -t '|' | awk -F '|' '{print $NF}'
   awk 'BEGIN {FS=","; OFS="|"} {print $NF,$0}' file.txt | sort -n -t '|' | awk -F '|' '{print $2}'
   awk 'BEGIN {FS=","; OFS="|"} {print $NF,$0}' file.txt | sort -n -t '|' | cut -d '|' -f 2
   ```

## Sources

- [Sort a file in Unix based on the last field]
- [The essential Bash cheat sheet]

<!-- project's references -->
<!-- in-article references -->
<!-- internal references -->
<!-- external references -->
[sort a file in unix based on the last field]: http://www.unixcl.com/2010/11/sort-file-based-on-last-field-unix.html
[the essential bash cheat sheet]: https://betterprogramming.pub/the-essential-bash-cheat-sheet-e1c3df06560
