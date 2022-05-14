# Sort

## TL;DR

```sh
# Sort given lines.
sort path/to/file

# Sort lines in reverse.
sort -r path/to/file

# Sort lines numerically.
sort -n path/to/file

# Sort lines and remove duplicates.
sort -u path/to/file

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

[sort a file in unix based on the last field]: http://www.unixcl.com/2010/11/sort-file-based-on-last-field-unix.html
