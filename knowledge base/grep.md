# Grep

## TL;DR

```shell
# base search
grep 'pattern' path/to/search

# recursive search
grep -R 'pattern' path/to/search/recursively
grep -R --exclude-dir excluded/dir 'pattern' path/to/search/recursively   # gnu grep >= 2.5.2

# show line numbers
grep -n 'pattern' path/to/search

# parallel execution
# mind the files with spaces in their name
find . -type f | parallel -j 100% grep 'pattern'
find . -type f -print0 | xargs -0 -n 1 -P $(nproc) grep 'pattern'
```

## Grep variants

- [`egrep`](#egrep) to use regular expressions in search patterns, same as `grep -E`
- [`fgrep`](#fgrep) to use patterns as fixed strings, same as `grep -F`
- [archive-related variants](#archive-related-variants) for searching into compressed files
- [`pdfgrep`](#pdfgrep) for searching into PDF files

### Archive-related variants

- [`xzgrep`](#xzgrep) (with `xzegrep` and `xzfgrep`)
- [`zstdgrep`](#zstdgrep) for zstd archives
- many many others

### PDFgrep

For simple searches, you might want to use [pdfgrep].

Should you need more advanced grep capabilities not incorporated by pdfgrep, you might want to convert the file to text and search there.  
You can to this using [pdftotext](pdfgrep.md) as shown in this example ([source][stackoverflow answer about how to search contents of multiple pdf files]):

```shell
find /path -name '*.pdf' -exec sh -c 'pdftotext "{}" - | grep --with-filename --label="{}" --color "your pattern"' ';'
```

## Gotchas

- Standard editions of `grep` run in a single thread; use another executor like
  `parallel` or `xargs` to parallelize grepping multiple files:

  ```shell
  find . -type f | parallel -j 100% grep 'pattern'
  find . -type f -print0 | xargs -0 -n 1 -P $(nproc) grep 'pattern'
  ```

  > mind files with spaces in their name.

## Further readings

- Answer on [StackOverflow] about [how to search contents of multiple pdf files]
- [Regular expressions in grep with examples]
- [Grep the standard error stream]
- Knowledge base on [pdfgrep]
- [Parallel grep]

[grep the standard error stream]: grep\ the\ standard\ error\ stream.md
[pdfgrep]: pdfgrep.md

[stackoverflow]: https://stackoverflow.com

[how to search contents of multiple pdf files]: https://stackoverflow.com/a/4643518
[parallel grep]: https://www.highonscience.com/blog/2021/03/21/parallel-grep/
[regular expressions in grep with examples]: https://www.cyberciti.biz/faq/grep-regular-expressions/
