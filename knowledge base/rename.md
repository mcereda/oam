# `rename`

> **Note:** this page refers to the command from the `util-linux` package on Linux or Homebrew's `rename` package.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Show what would change without changing anything (dry run).
rename -vn foo bar *

rename -n 's/^(\d{4}-\d{2}-\d{2})  (.*)$/$1  addition  $2/' 'file'
rename -n 's/^What.*(\d{4}-\d{2}-\d{2}) at (\d{2}\.\d{2}.\d{2}\..*)/$1 $2/' *
```

## Sources

- [cheat.sh]
- [How to use the rename command on Linux]

<!--
  References
  -->

<!-- Others -->
[cheat.sh]: https://cheat.sh/rename
[How to Use the rename Command on Linux]: https://www.howtogeek.com/423214/how-to-use-the-rename-command-on-linux/
