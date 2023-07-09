# Split

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Break the 'home.tar.bz2' archive file into small blocks.
# Each block up to 10MB (10\*1000\*1000) in size.
# Prefix each chunk with 'home.tar.bz2.part'.
split -b 10M home.tar.bz2 "home.tar.bz2.part"

# Break the 'logs.tgz' file into 2M (2\*1024\*1024) bytes blocks.
# Number them in the suffix.
split -b 2M -d logs.tgz "logs.tgz."
```

## Sources

- [split large tar into multiple files of certain size]
- [create a tar archive split into blocks of a maximum size]

<!--
  References
  -->

<!-- Others -->
[create a tar archive split into blocks of a maximum size]: https://unix.stackexchange.com/questions/61774/create-a-tar-archive-split-into-blocks-of-a-maximum-size
[split large tar into multiple files of certain size]: https://www.tecmint.com/split-large-tar-into-multiple-files-of-certain-size/
