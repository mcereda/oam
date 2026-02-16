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

<details style='padding: 0 0 1rem 0'>
  <summary>Setup</summary>

```sh
brew install --cask 'ollama-app'  # or just brew install 'ollama'
curl -fsSL 'https://ollama.com/install.sh' | sh
docker pull 'ollama/ollama'

# Run in containers.
docker run -d -v 'ollama:/root/.ollama' -p '11434:11434' --name 'ollama' 'ollama/ollama'
docker run -d --gpus='all' … 'ollama/ollama'

# Expose (bind) the server to specific IP addresses and/or with custom ports.
# Default is 127.0.0.1 on port 11434.
# Only valid for the *'serve'* command.
OLLAMA_HOST='some.fqdn:11435' ollama serve

# Use a custom context length.
# Only valid for the *'serve'* command.
OLLAMA_CONTEXT_LENGTH=64000 ollama serve

# Use a remotely served model.
# Valid for all commands *but* 'serve'.
OLLAMA_HOST='some.fqdn:11435' ollama …
```

</details>

The maximum context for model execution can be set in the app.<br/>
If so, using `OLLAMA_CONTEXT_LENGTH` in the CLI seems to have no effect. The app's setting is used regardless.

<details style='padding: 0 0 1rem 0'>
  <summary>Performance examples</summary>

Prompt: `Hi! Are you there?`.<br/>
The model was run once right before the tests started to remove loading times.<br/>
Requests have been sent in headless mode (`ollama run 'model' 'prompt'`).

  <details style='padding: 0 0 0 1rem'>
    <summary><code>glm-4.7-flash:q4_K_M</code> on an M3 Pro MacBook Pro 36 GB</summary>

Model: `glm-4.7-flash:q4_K_M`.<br/>
Host: M3 Pro MacBook Pro 36 GB.

| Context | RAM Usage | Used swap    | Average response time | System remained responsive   |
| ------: | --------: | ------------ | --------------------: | ---------------------------- |
|    4096 |     19 GB | No           |                 9.27s | Yes                          |
|    8192 |     19 GB | No           |                 8.28s | Yes                          |
|   16384 |     20 GB | No           |                 9.13s | Yes                          |
|   32768 |     22 GB | No           |                 9.05s | Yes                          |
|   65536 |     25 GB | No? (unsure) |                10.07s | Meh (minor stutters)         |
|  131072 |     33 GB | **Yes**      |                18.43s | **No** (noticeable stutters) |

  </details>

</details>

The API are available after installation at <http://localhost:11434/api> as default.

Cloud models are automatically offloaded to Ollama's cloud service.<br/>
This allows to keep using one's local tools while running larger models that wouldn't fit on a personal computer.<br/>
Those models are _usually_ tagged with the `cloud` suffix.

Thinking is enabled by default in the CLI and API for models that support it.<br/>
Some of those models (e.g. `gpt-oss`) also (or only) allow to set thinking levels.

Vision models accept images alongside text.<br/>
The model can describe, classify, and answer questions about what it sees.

<details>
  <summary>Usage</summary>

```sh
# Start the server.
ollama serve

# Verify the server is running.
curl 'http://localhost:11434/'

# Access the API via cURL.
curl 'http://localhost:11434/api/generate' -d '{
  "model": "gemma3",
  "prompt": "Why is the sky blue?"
}'

# Start the interactive menu.
ollama
ollama launch

# Download models.
ollama pull 'qwen2.5-coder:7b'
ollama pull 'glm-4.7:cloud'

# List pulled models.
ollama list
ollama ls

# Show models information.
ollama show 'codellama:13b'

# Run models interactively.
ollama run 'gemma3'
docker exec -it 'ollama' ollama run 'llama3.2'

# Run headless.
ollama run 'glm-4.7-flash:q4_K_M' 'Hi! Are you there?' --verbose
ollama run 'deepseek-r1' --think=false "Summarize this article"
ollama run 'gemma3' --hidethinking "Is 9.9 bigger or 9.11?"
ollama run 'gpt-oss' --think=low "Draft a headline"
ollama run 'gemma3' './image.png' "what's in this image?" --temperature '0.8' --top-p '0.9'

# Launch integrations.
ollama launch 'opencode'
ollama launch 'claude' --model 'glm-4.7-flash'
ollama launch 'openclaw'

# Only configure models used by integrations.
# Do *not* launch them.
ollama launch 'opencode' --config
ollama launch 'claude' --config

# Check usage.
ollama ps

# Stop running models.
ollama stop 'gemma3'

# Delete models.
ollama rm 'gemma3'
ollama rm 'nomic-embed-text:latest' 'llama3.1:8b'

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
- [Models library]

### Sources

- [Documentation]
- [The Complete Guide to Ollama: Run Large Language Models Locally]

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
[Models library]: https://ollama.com/library
[Website]: https://ollama.com/

<!-- Others -->
[The Complete Guide to Ollama: Run Large Language Models Locally]: https://dev.to/ajitkumar/the-complete-guide-to-ollama-run-large-language-models-locally-2mge
