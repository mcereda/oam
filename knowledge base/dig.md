# Dig

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Installation.
apt-get install 'dnsutils'
yum install 'bind-utils'

# Perform a DNS lookup.
dig 'google.com'
dig 'google.com' 'A'

# Perform a reverse lookup.
dig -x '172.217.14.238'

# Only show the IP from the result.
dig 'google.com' '+short'

# Do not echo the executed command.
# This is a global flag, notice the position.
dig +nocmd 'google.com'

# Clear display flags.
dig 'google.com' +noall

# Do not display the answer section of replies.
dig 'google.com' +noanswer

# Print records in a verbose multi-line format with human-readable comments.
dig 'google.com' +multiline

# See resolution trace.
dig 'google.com' '+trace'

# Ask a specific DNS server.
dig '@8.8.8.8' 'google.com'

# Return all results.
dig 'google.com' 'ANY'
```

## Sources

- [How to Use Linux dig Command (DNS Lookup)]
- [Using dig +trace to Understand DNS Resolution from Start to Finish]

<!--
  References
  -->

<!-- Others -->
[how to use linux dig command (dns lookup)]: https://phoenixnap.com/kb/linux-dig-command-examples
[using dig +trace to understand dns resolution from start to finish]: https://ns1.com/blog/using-dig-trace
