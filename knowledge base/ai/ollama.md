# Ollama

One of the easiest way to get up and running with large language models.<br/>
Emerged as one of the most popular tools for local LLM deployment.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Leverages [llama.cpp].

Supports primarily the GGUF file format with quantization levels Q2_K through Q8_0.<br/>
Offers automatic conversion of models from Hugging Face and allows customization through Modelfile.

Supports tool calling functionality via API.<br/>
Models can decide when to invoke tools and how to use returned data.<br/>
Works with models specifically trained for function calling (e.g., Mistral, Llama 3.1, Llama 3.2, and Qwen2.5). However,
it does not currently allow forcing a specific tool to be called nor receiving tool call responses in streaming mode.

Considered ideal for developers who prefer CLI interfaces and automation, need reliable API integration, value
open-source transparency, and want efficient resource utilization.

Excellent for building applications that require seamless migration from OpenAI.

<details>
  <summary>Setup</summary>

```sh
brew install --cask 'ollama-app'  # or just brew install 'ollama'
docker pull 'ollama/ollama'

# Run in containers.
docker run -d -v 'ollama:/root/.ollama' -p '11434:11434' --name 'ollama' 'ollama/ollama'
docker run -d --gpus='all' … 'ollama/ollama'
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
ollama ls

# Start Ollama.
ollama serve
OLLAMA_CONTEXT_LENGTH=64000 ollama serve

# Run models.
ollama run 'gemma3'
docker exec -it 'ollama' ollama run 'llama3.2'

# Quickly set up a coding tool with Ollama models.
ollama launch

# Launch models.
ollama launch 'claude' --model 'glm-4.7-flash'

# Only configure models.
# Do *not* launch them.
ollama launch 'claude' --config

# Check usage.
ollama ps

# Stop running models.
ollama stop 'gemma3'

# Delete models.
ollama rm 'gemma3'

# Create custom models.
# Requires a Modelfile.
ollama create -f 'Modelfile'

# Quantize models.
# Requires a Modelfile.
ollama create --quantize 'q4_K_M' 'llama3.2'

# Push models to Ollama.
ollama push 'myuser/mymodel'

# Clone models.
ollama cp 'mymodel' 'myuser/mymodel'

# Sign into Ollama cloud, or create a new account.
ollama signin

# Sign out from Ollama cloud.
ollama signout
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
[llama.cpp]: llama.cpp.md

<!-- Files -->
<!-- Upstream -->
[Blog]: https://ollama.com/blog
[Codebase]: https://github.com/ollama/ollama
[Documentation]: https://docs.ollama.com/
[Website]: https://ollama.com/

<!-- Others -->
