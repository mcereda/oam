# `comm`

Compares two files line by line.

With no options, produces 3 columns in output:

- column 1 contains lines **unique to file 1**;
- column 2 contains lines **unique to file 2**;
- column 3 contains lines **common** to both files.

Comparisons honor the rules specified by 'LC_COLLATE'.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

<details>
  <summary>Usage</summary>

```sh
# Print only lines present in both file1 and file2.
comm -12 'path/to/pre-sorted/file1' 'path/to/pre-sorted/file2'

# Print unique lines of file1 which are not present in file2.
comm -23 'path/to/pre-sorted/file1' 'path/to/pre-sorted/file2'
comm -23 <(sort -u 'path/to/file1') <(sort -u 'path/to/file2')

# Check the whole content of file1 is present in file2.
test $(comm -23 'path/to/pre-sorted/file1' <(sort -u 'path/to/file2') | wc -l) -eq 0
[[ $(comm -23 <(sort -u 'path/to/file1') 'path/to/pre-sorted/file2' | wc -l) -eq 0 ]]
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# List security groups not used by EC2 instances in AWS.
comm -23 \
  <( aws ec2 describe-security-groups --query 'SecurityGroups[*].GroupId' --output 'text' | tr '\t' '\n' | sort ) \
  <( \
    aws ec2 describe-instances --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output 'text' \
    | tr '\t' '\n' | sort | uniq \
  )
```

</details>

## Further readings

- [`cmp`][cmp]
- [man page]

## Sources

All the references in the [further readings] section, plus the following:

- [Check whether all lines of file occur in different file]
- [6 more terminal commands you should know]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[cmp]: cmp.md

<!-- Others -->
[6 more terminal commands you should know]: https://betterprogramming.pub/6-more-terminal-commands-you-should-know-3606cecdf8b6
[check whether all lines of file occur in different file]: https://unix.stackexchange.com/questions/397747/check-whether-all-lines-of-file-occur-in-different-file#397749
[man page]: https://linux.die.net/man/1/comm
