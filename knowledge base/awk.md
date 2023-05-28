# `awk`

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Print only the 3rd column.
awk '{print $3}' sales.txt
cat sales.txt | awk '{print $3}'

# Print the 2nd and 3rd columns, separated with a comma.
awk '{print $2 ", " $3}' sales.txt
cat sales.txt | awk '{print $2 ", " $3}'

# Print the sum of the 2nd and 3rd columns.
awk '{print $2 + $3}' sales.txt

# Print only lines with a length of more than 20 characters.
awk 'length($0) > 20' sales.txt

# Print only lines where the value of the second column is greater than 100.
awk '$2 > 100' sales.txt
```

## Further readings

- [Print line only if number in third field is greater than X]
- [Printing the last column of a line in a file]
- [The essential Bash cheat sheet]

<!-- project's references -->
<!-- in-article references -->
<!-- internal references -->
<!-- external references -->
[print line only if number in third field is greater than x]: https://unix.stackexchange.com/questions/395588/print-line-only-if-number-in-third-field-is-greater-than-x#395593
[printing the last column of a line in a file]: https://stackoverflow.com/questions/13046167/printing-the-last-column-of-a-line-in-a-file#13046224
[the essential bash cheat sheet]: https://betterprogramming.pub/the-essential-bash-cheat-sheet-e1c3df06560
