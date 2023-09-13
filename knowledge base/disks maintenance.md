# Disks maintenance

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Check disks have spun down.
# 'standby' means they did.
smartctl -i -n standby '/dev/sda'
hdparm -C '/dev/sd'*
```

## Sources

- [`smartctl`][smartctl]
- [`hdparm`][hdparm]

<!--
  References
  -->

<!-- Knowledge base -->
[hdparm]: hdparm.md
[smartctl]: smartctl.md
