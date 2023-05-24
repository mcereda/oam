# Title

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

Files in `/etc/cron.hourly` and similar need to:

- be executable,
- match the Debian cron script namespace (`^[a-zA-Z0-9_-]+$`, so script **with an extension** won't work).

```sh
# Print the names of the scripts which would be invoked.
sudo run-parts --report --test '/etc/cron.hourly'
```

## Further readings

## Sources

All the references in the [further readings] section, plus the following:

- [Function of /etc/cron.hourly]

<!-- project's references -->

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
[Function of /etc/cron.hourly]: https://askubuntu.com/questions/7676/function-of-etc-cron-hourly#607974
