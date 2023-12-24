# Send an email from CLI

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
mail -s "Subject" recipient@mail.server
echo "" | mail -a attachment.file -s "Subject" recipient@mail.server

# send larger files
cat file.txt | mail -s "Subject" recipient@mail.server

# make "email-safe" the contents of a file
uuencode file.txt | mail -s "Subject" recipient@mail.server
```

## Further readings

- [linux mail command examples]
- [uuencode]

<!--
  References
  -->

<!-- Others -->
[linux mail command examples]: https://www.binarytides.com/linux-mail-command-examples/
[uuencode]: https://linux.101hacks.com/unix/uuencode/
