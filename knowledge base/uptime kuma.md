# Uptime Kuma

TODO

Fancy and easy-to-use self-hosted monitoring tool.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Only **one** user as of 2024-06-01.

<details>
  <summary>Installation and configuration</summary>

```sh
docker pull 'louislam/uptime-kuma:1'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Start.
docker run -d --restart 'always' --name 'uptime-kuma' -p '3001:3001' -v 'uptime-kuma:/app/data' 'louislam/uptime-kuma:1'

# Password reset.
docker exec -it 'uptime-kuma' npm run reset-password
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
- [Github]
- [Documentation]
- [`uptime-kuma-api`][uptime-kuma-api]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[documentation]: https://github.com/louislam/uptime-kuma/wiki
[github]: https://github.com/louislam/uptime-kuma
[uptime-kuma-api]: https://github.com/lucasheld/uptime-kuma-api
[website]: https://uptime.kuma.pet/

<!-- Others -->
