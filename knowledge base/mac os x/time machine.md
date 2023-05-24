# Time Machine

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Follow logs](#follow-logs)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Follow logs.
log stream --style 'syslog' \
  --predicate 'senderImagePath contains[cd] "TimeMachine"' \
  --info --debug

# Add or set a destination.
sudo tmutil setdestination
```

## Follow logs

- Use `stream` to keep watching "tail style".
- Use `--predicate` to filter out only relevant logs.
- Add `--style 'syslog'` to print them out like `syslog` on Linux would.

## Further readings

- [Mac OS X]

## Sources

All the references in the [further readings] section, plus the following:

<!-- project's references -->

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
[mac os x]: README.md

<!-- external references -->
