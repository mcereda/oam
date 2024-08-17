# Immich

Self-hosted photo and video management solution.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
curl -O 'https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml' \
&& curl -o '.env' 'https://github.com/immich-app/immich/releases/latest/download/example.env' \
&& curl -O 'https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml' \
&& curl -O 'https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml' \
&& docker compose up -d \
&& xdg-open 'http://localhost:2283'
```

The composition uses `.env` for configuration.<br/>
Refer the [Environment Variables] documentation page for the available environment variables.
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
- [Environment Variables]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[environment variables]: https://immich.app/docs/install/environment-variables
[main repository]: https://github.com/immich-app/immich
[website]: https://immich.app/

<!-- Others -->
