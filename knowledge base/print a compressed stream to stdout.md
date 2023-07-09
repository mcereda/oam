# Print a compressed stream to stdout

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
cat file.zip | zcat
cat file.zip | busybox unzip -p -
cat file.gz | gunzip -c -
curl 'https://example.com/some.zip' | bsdtar -xOf -
```

## Sources

- [Unzip from stdin to stdout]

<!--
  References
  -->

<!-- Others -->
[unzip from stdin to stdout]: https://serverfault.com/questions/735882/unzip-from-stdin-to-stdout-funzip-python
