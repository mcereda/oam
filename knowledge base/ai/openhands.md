# OpenHands

Community focused on AI-driven development.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
docker pull 'docker.openhands.dev/openhands/runtime:1.2-nikolaik'
docker run -it --rm --name 'openhands-app' --pull='always' \
  -e 'AGENT_SERVER_IMAGE_REPOSITORY=docker.openhands.dev/openhands/runtime' \
  -e 'AGENT_SERVER_IMAGE_TAG=1.2-nikolaik' \
  -e 'LOG_ALL_EVENTS=true' \
  -v '/var/run/docker.sock:/var/run/docker.sock' \
  -v "$HOME/.openhands:/.openhands" \
  -p '3000:3000' \
  --add-host 'host.docker.internal:host-gateway' \
  'docker.openhands.dev/openhands/openhands:1.2'
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
- [Codebase]
- [Blog]

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
[Blog]: https://openhands.dev/blog
[Codebase]: https://github.com/OpenHands/OpenHands
[Documentation]: https://docs.openhands.dev/
[Website]: https://openhands.dev/

<!-- Others -->
