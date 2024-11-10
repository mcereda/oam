# Title

AWS service emulator that runs in a single container.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install 'localstack/tap/localstack-cli'
localstack --version

# Install on Kubernetes
helm -n 'localstack' upgrade -i --create-namespace 'localstack' --repo 'https://helm.localstack.cloud' 'localstack'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Validate the configuration
localstack config validate

# Run
docker run --rm -it \
  -p '127.0.0.1:4566:4566' -p '127.0.0.1:4510-4559:4510-4559' \
  -v '/var/run/docker.sock:/var/run/docker.sock' \
  'localstack/localstack'
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
- [Documentation]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/localstack/localstack
[documentation]: https://docs.localstack.cloud/
[website]: https://www.localstack.cloud/

<!-- Others -->
