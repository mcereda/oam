# uv

Fast Python package and project manager written in Rust.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install 'uv'
docker pull 'ghcr.io/astral-sh/uv:0.10.4-python3.12-trixie'
pip install 'uv'
pipx install 'uv'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Install applications.
# Similar to `pipx install`.
uv tool install 'ansible'

# List installed applications.
uv tool list

# Run applications.
# Similar to `pipx run`.
uv tool run 'vllm'
uvx 'vllm'          # alias for `uv tool run`

# Clear the cache.
uv cache clean
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
[Codebase]: https://github.com/astral-sh/uv
[Documentation]: https://docs.astral.sh/uv/
[Website]: https://docs.astral.sh/uv/

<!-- Others -->
