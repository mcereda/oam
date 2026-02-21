# vLLM Metal plugin

Community maintained hardware plugin for vLLM on Apple Silicon.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Plugin that enables vLLM to run on Apple Silicon Macs using MLX as the primary compute backend, enabling higher
performances.

<details>
  <summary>Setup</summary>

> [!important]
> Use Python v3.10 to v3.12 as per 2026-02-21.<br/>
> Python 3.13 is not yet supported.

```sh
# Install from sources.
git clone 'https://github.com/vllm-project/vllm-metal.git' \
&& cd 'vllm-metal' \
&& pip install -e '.' 'https://github.com/vllm-project/vllm/releases/download/v0.15.1/vllm-0.15.1.tar.gz'

# Use the provided installation script.
curl -fsSL 'https://raw.githubusercontent.com/vllm-project/vllm-metal/main/install.sh' | bash
```

</details>

Refer [vLLM] for usage.

## Further readings

- [vLLM]
- [Codebase]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[vLLM]: vllm.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/vllm-project/vllm-metal

<!-- Others -->
