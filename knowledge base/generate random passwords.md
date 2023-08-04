# Generate random passwords

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Print out 32 random characters.
openssl rand -base64 32
gpg --gen-random --armor 1 32

# Print out 32 random alphanumerical characters.
date '+%s' | sha256sum | base64 | head -c '32'
cat '/dev/urandom' | LC_ALL='C' tr -dc '[:alnum:]' | fold -w '32' | head -n '1'

# XKCD-inspired passwords.
pipx run 'xkcdpass'
```

## Sources

- [10 ways to generate a random password from the Linux command line]
- [Generate a random password on Linux]

<!--
  References
  -->

<!-- Others -->
[10 ways to generate a random password from the linux command line]: https://www.howtogeek.com/30184/10-ways-to-generate-a-random-password-from-the-command-line/
[generate a random password on linux]: https://linuxhint.com/generate-random-password-linux/
