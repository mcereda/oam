# `agg`

Command-line tool for generating animated GIF files from asciicast files produced by [Asciinema].

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Installation.
brew install agg

# Convert asciicast files from Asciinema.
agg 'path/to/file.cast' 'path/to/file.gif'
agg --rows '48' --speed '1.25' --renderer resvg --no-loop 'in.cast' 'out.gif'
```

## Further readings

- [Asciinema] to record terminal sessions
- [VHS] as an alternative to Asciinema

<!--
  References
  -->

<!-- Knowledge base -->
[asciinema]: asciinema.md
[vhs]: vhs.md
