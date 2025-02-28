# Apache HTTP server benchmarking tool

> TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
apt install 'apache2-utils'
dnf install 'httpd-tools'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Limited number of requests
ab -n '750' -c '1' 'http://grafana.example.org/'

# Sustained load for 't' seconds
# Default requests limit is 50000
ab -t 300 -c 100 http://192.168.29.20/
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]

### Sources

- [Load Testing in Linux With ApacheBench (ab)]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[website]: https://httpd.apache.org/docs/current/programs/ab.html

<!-- Others -->
[load testing in linux with apachebench (ab)]: https://www.baeldung.com/linux/ab-apachebench-load-testing
