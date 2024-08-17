# Watchtower

Container-based solution for automating Docker container base image updates.

> Intended to be used in homelabs, media centers, local dev environments, and such.<br/>
> **Not** recommend in commercial or production environments.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
docker run -d --name 'watchtower' -v '/var/run/docker.sock:/var/run/docker.sock' 'containrrr/watchtower'
```

Docker compose:

```yaml
services:
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

</details>

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Main repository]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[main repository]: https://github.com/containrrr/watchtower/
[website]: https://containrrr.dev/watchtower/

<!-- Others -->
