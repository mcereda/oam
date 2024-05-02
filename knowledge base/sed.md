# SED

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Character classes and bracket expressions](#character-classes-and-bracket-expressions)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Quote any set of characters that is not a space.
sed -E 's|([[:graph:]]+)|"\1"|g'

# Delete lines matching "OAM" from a file.
# Overwrite the source file with the changes.
sed '/OAM/d' -i .bash_history

# Show changed fstab entries.
# Don't save the changes.
sed /etc/fstab \
  -e "s|#.*\s*/boot\s*.*|/dev/sda1  /boot  vfat   defaults             0 0|" \
  -e "s|#.*\s*ext4\s*.*|/dev/sda2  /      btrfs  compress-force=zstd  0 0|" \
  -e '/#.*\s*swap\s*.*/d'
```

## Character classes and bracket expressions

| Class | Description |
| ----- | ----------- |
| `[[:alnum:]]`  | alphanumeric characters `[[:alpha:]]` and `[[:digit:]]`; this is the same as `[0-9A-Za-z]` in the `C` locale and ASCII character |
| `[[:alpha:]]`  | alphabetic characters `[[:lower:]]` and `[[:upper:]]`; this is the same as `[A-Za-z]` in the `C` locale and ASCII character encoding |
| `[[:blank:]]`  | blank characters `space` and `tab` |
| `[[:cntrl:]]`  | control characters; in ASCII these characters have octal codes 000 through 037 and 177 (DEL), in other character sets these are the equivalent characters, if any |
| `[[:digit:]]`  | digits `0` to `9` |
| `[[:graph:]]`  | graphical characters `[[:alnum:]]` and `[[:punct:]]` |
| `[[:lower:]]`  | lower-case letters `a` to `z` in the `C` locale and ASCII character encoding |
| `[[:print:]]`  | printable characters `[[:alnum:]]`, `[[:punct:]]` and `space` |
| `[[:punct:]]`  | punctuation characters `!`, `"`, `#`, `$`, `%`, `&`, `'`, `(`, `)`, `*`, `+`, `,`, `-`, `.`, `/`, `:`, `;`, `<`, `=`, `>`, `?`, `@`, `[`, `\`, `]`, `^`, `_`, `` ` ``, `{`, `\|`, `}` and `~` in the `C` locale and ASCII character encoding |
| `[[:space:]]`  | space characters `tab`, `newline`, `vertical tab`, `form feed`, `carriage return` and `space` in the `C` locale |
| `[[:upper:]]`  | upper-case letters `A` to `Z` in the `C` locale and ASCII character encoding |
| `[[:xdigit:]]` | hexadecimal digits `0` to `9`, `A` to `F` and `a` to `f` |

## Further readings

- [GNU SED Online Tester]
- [Character Classes and Bracket Expressions]

<!--
  References
  -->

<!-- Upstream -->
[character classes and bracket expressions]: https://www.gnu.org/software/sed/manual/html_node/Character-Classes-and-Bracket-Expressions.html

<!-- Others -->
[gnu sed online tester]: https://sed.js.org/
