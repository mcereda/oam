# Title

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

Files in `/etc/cron.hourly` and similar need to:

- be executable,
- match the Debian cron script namespace (`^[a-zA-Z0-9_-]+$`, so script **with an extension** won't work).

```sh
# Print the names of the scripts which would be invoked.
sudo run-parts --report --test '/etc/cron.hourly'
```

## Sources

- [Function of /etc/cron.hourly]

<!--
  References
  -->

<!-- Others -->
[Function of /etc/cron.hourly]: https://askubuntu.com/questions/7676/function-of-etc-cron-hourly#607974
