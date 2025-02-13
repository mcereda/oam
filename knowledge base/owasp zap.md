# Zed Attack Proxy

Widely used free and open source web app scanner.

Helps automatically find security vulnerabilities in web applications.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
docker pull 'zaproxy/zap-stable'  # or 'ghcr.io/zaproxy/zaproxy:stable'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Get a shell in the container.
docker run --rm --name 'zap' -ti 'zaproxy/zap-stable'

# Start the Web UI.
docker run --rm --name 'web-ui' -d -u 'zap' -p '8080:8080' -p '8090:8090' 'zaproxy/zap-stable' zap-webswing.sh \
&& open 'http://localhost:8080/zap/'

# Start API scans.
docker run --rm --name 'api-scan' 'zaproxy/zap-stable' zap-api-scan.py -t 'http://localhost:3000/api/v1/' -f 'openapi'
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
- [Codebase]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/zaproxy/zaproxy
[documentation]: https://www.zaproxy.org/docs/
[website]: https://www.zaproxy.org/

<!--
https://www.zaproxy.org/docs/docker/about/
https://www.zaproxy.org/docs/docker/api-scan/
https://www.zaproxy.org/docs/docker/webswing/
-->

<!-- Others -->
