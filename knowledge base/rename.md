# `rename`

> **Note:** this page refers to the command from the `util-linux` package on Linux or Homebrew's `rename` package.

## TL;DR

```sh
# Show what would change without changing anything (dry run).
rename -vn foo bar *

rename -nv 's/^(\d{4}-\d{2}-\d{2})  (.*)$/$1  addition  $2/' 'file'
```

## Sources

- [cheat.sh]
- [How to use the rename command on Linux]

<!-- external references -->
[cheat.sh]: https://cheat.sh/rename
[How to Use the rename Command on Linux]: https://www.howtogeek.com/423214/how-to-use-the-rename-command-on-linux/
