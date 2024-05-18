# Vaultwarden

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation and configuration</summary>

```sh
docker pull 'vaultwarden/server'
```

</details>

<details>
  <summary>Usage</summary>

```sh
docker run -d --name vaultwarden -v /vw-data/:/data/ --restart unless-stopped -p 80:80 vaultwarden/server:latest
```

</details>

## Further readings

- [Github]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[github]: https://github.com/dani-garcia/vaultwarden

<!-- Others -->
