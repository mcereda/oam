# Iperf

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Server side.
iperf3 -s
iperf3 -f M -s -p '7575'

# Client side.
iperf3 -f K -c 'iperf.server.ip'
iperf3 -c 'iperf.server.ip' -p '7575'
```

## Sources

- [How to use iPerf3 to test network bandwidth]

<!--
  References
  -->

<!-- Others -->
[how to use iperf3 to test network bandwidth]: https://www.techtarget.com/searchnetworking/tip/How-to-use-iPerf-to-measure-throughput
