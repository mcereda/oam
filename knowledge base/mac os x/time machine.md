# Time Machine

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Follow logs](#follow-logs)
1. [Further readings](#further-readings)

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

<!--
  References
  -->

<!-- Knowledge base -->
[mac os x]: README.md
