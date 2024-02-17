# Grep

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Variants](#variants)
   1. [Archive-related variants](#archive-related-variants)
   1. [PDFgrep](#pdfgrep)
1. [Gotchas](#gotchas)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Basic search.
grep 'pattern' 'path/to/search'

# Search recursively.
grep -R 'pattern' 'path/to/search/recursively'
grep -R --exclude-dir 'excluded/dir' 'pattern' 'path/to/search/recursively'   # gnu grep >= 2.5.2

# Show line numbers.
grep -n 'pattern' 'path/to/search'

# Only print the part matching the pattern.
ps | grep -o '/.*/fish' | head -n '1'

# Multiple parallel searches.
# Mind files with spaces in their name.
find . -type f | parallel -j +100% grep 'pattern'
find . -type f -print0 | xargs -0 -n 1 -P "$(nproc)" grep 'pattern'

# Highlight numbers in strings.
grep --color '[[:digit:]]' 'file.txt'
```

## Variants

- `egrep` to use regular expressions in search patterns, same as `grep -E`
- `fgrep`] to use patterns as fixed strings, same as `grep -F`
- [archive-related variants](#archive-related-variants) for searching into compressed files
- [`pdfgrep`](#pdfgrep) for searching into PDF files

### Archive-related variants

- `xzgrep` (with `xzegrep` and `xzfgrep`)
- `zstdgrep` for zstd archives
- many many others

### PDFgrep

For simple searches, you might want to use [pdfgrep].

Should you need more advanced grep capabilities not incorporated by pdfgrep, you might want to convert the file to text and search there.<br/>
You can to this using [pdftotext](pdfgrep.md) as shown in this example ([source][stackoverflow answer about how to search contents of multiple pdf files]):

```sh
find /path -name '*.pdf' -exec sh -c 'pdftotext "{}" - | grep --with-filename --label="{}" --color "your pattern"' ';'
```

## Gotchas

- Standard editions of `grep` run in a single thread; use another executor like
  `parallel` or `xargs` to parallelize grepping multiple files:

  ```sh
  find . -type f | parallel -j 100% grep 'pattern'
  find . -type f -print0 | xargs -0 -n 1 -P $(nproc) grep 'pattern'
  ```

  > mind files with spaces in their name.

## Further readings

- [Grep the standard error stream]
- [`pdfgrep`][pdfgrep]

## Sources

All the references in the [further readings] section, plus the following:

- Answer on [StackOverflow] about [how to search contents of multiple pdf files]
- [Regular expressions in grep with examples]
- [Parallel grep]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[grep the standard error stream]: grep%20the%20standard%20error%20stream.md
[pdfgrep]: pdfgrep.md

<!-- Others -->
[how to search contents of multiple pdf files]: https://stackoverflow.com/a/4643518
[parallel grep]: https://www.highonscience.com/blog/2021/03/21/parallel-grep/
[regular expressions in grep with examples]: https://www.cyberciti.biz/faq/grep-regular-expressions/
[stackoverflow]: https://stackoverflow.com
