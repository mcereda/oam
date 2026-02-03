# Ollama

The easiest way to get up and running with large language models.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install --cask 'ollama-app'  # or just brew install 'ollama'
```

</details>

Cloud models are automatically offloaded to Ollama's cloud service.<br/>
This allows to keep using one's local tools while running larger models that wouldn't fit on a personal computer.<br/>
Those models are _usually_ tagged with the `cloud` suffix.

<details>
  <summary>Usage</summary>

```sh
# Download models.
ollama pull 'qwen2.5-coder:7b'
ollama pull 'glm-4.7:cloud'

# List pulled models.
ollama list

# Run models.
ollama run 'gemma3'

# Quickly set up a coding tool with Ollama models.
ollama launch

# Launch models.
ollama launch 'claude' --model 'glm-4.7-flash'

# Only configure model, without launching them.
ollama launch 'claude' --config

# Sign into Ollama cloud, or create a new account.
ollama signin
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
[Blog]: https://ollama.com/blog
[Codebase]: https://github.com/ollama/ollama
[Documentation]: https://docs.ollama.com/
[Website]: https://ollama.com/

<!-- Others -->
