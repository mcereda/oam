# llama.cpp

> TODO

LLM inference engine written in in C/C++.<br/>
Vastly used as base for AI tools like [Ollama] and [Docker model runner].

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install 'llama.cpp'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# List available devices and exit.
llama-cli --list-devices

# List models in cache.
llama-cli -cl
llama-cli --cache-list

# Run models from files interactively.
llama-cli -m 'path/to/model.gguf'
llama-cli -m 'path/to/target/model.gguf' -md 'path/to/draft/model.gguf'

# Download and run models.
llama-cli -mu 'https://example.org/some/model'  # URL
llama-cli -hf 'ggml-org/gemma-3-1b-it-GGUF' -c '32.768'  # Hugging Face
llama-cli -dr 'ai/qwen2.5-coder' --offline  # Docker Hub

# Launch the OpenAI-compatible API server.
llama-server -m 'path/to/model.gguf'
llama-server -hf 'ggml-org/gemma-3-1b-it-GGUF' --port '8080' --host '127.0.0.1'

# Run benchmarks.
llama-bench -m 'path/to/model.gguf'
llama-bench -m 'models/7B/ggml-model-q4_0.gguf' -m 'models/13B/ggml-model-q4_0.gguf' -p '0' -n '128,256,512' --progress
```

The web UI can be accessed via browser at <http://localhost:8080>.<br/>
The chat completion endpoint it at <http://localhost:8080/v1/chat/completions>.

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Use models pulled with Ollama.
jq -r '.layers|sort_by(.size)[-1].digest|sub(":";"-")' \
  "$HOME/.ollama/models/manifests/registry.ollama.ai/library/codellama/13b" \
| xargs -pI '%%' llama-bench -m "$HOME/.ollama/models/blobs/%%" --progress
```

</details>

## Further readings

- [Website]
- [Codebase]
- [ik_llama.cpp]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Docker model runner]: ../docker.md#running-llms-locally
[Ollama]: ollama.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/ggml-org/llama.cpp
[Website]: https://llama-cpp.com/

<!-- Others -->
[ik_llama.cpp]: https://github.com/ikawrakow/ik_llama.cpp
