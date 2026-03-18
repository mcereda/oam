# vLLM

Open source library for LLM inference and serving.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Engineered specifically for high-performance, production-grade LLM inference.

Enables _local execution_ of [Language Models].

Offers production-ready, highly mature OpenAI-compatible API.<br/>
Has full support for streaming, embeddings, tool/function calling with parallel invocation capability, vision-language
model support, rate limiting, and token-based authentication. Optimized for high-throughput and batch requests.

Supports PyTorch and Safetensors (primary), GPTQ and AWQ quantization, native Hugging Face model hub.<br/>
Does **not** natively support GGUF (requires conversion).

Offers production-grade, fully-featured, OpenAI-compatible tool calling functionality via API.<br/>
Support includes parallel function calls, the `tool_choice parameter` for controlling tool selection, and streaming
support for tool calls.

Considered the gold standard for production deployments requiring enterprise-grade tool orchestration.<br/>
Best for production-grade performance and reliability, high concurrent request handling, multi-GPU deployment
capabilities, and enterprise-scale LLM serving.

<details>
  <summary>Setup</summary>

> [!tip]
> Prefer using [vLLM-metal] on Apple silicon.

```sh
pip install 'vllm'
pipx install 'vllm'
uv tool install 'vllm'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Get help.
vllm --help

# Start the vLLM OpenAI Compatible API server.
vllm serve 'meta-llama/Llama-2-7b-hf'
vllm serve '/path/to/local/model'
vllm serve … --port '8000' --gpu-memory-utilization '0.9'
vllm serve … --tensor-parallel-size '2' --uds '/tmp/vllm.sock'

# Chat.
vllm chat
vllm chat --url 'http://vllm.example.org:8000/v1'
vllm chat --quick "hi"

# Generate text completion.
vllm complete
vllm complete --url 'http://vllm.example.org:8000/v1'
vllm complete --quick "The future of AI is"

# Bench vLLM.
vllm bench latency --model '…' --input-len '32' --output-len '1' --enforce-eager --load-format 'dummy'
vllm bench serve --host 'localhost' --port '8000' --model '…' \
  --random-input-len '32' --random-output-len '4' --num-prompts '5'
vllm bench throughput --model '…' --input-len '32' --output-len '1' --enforce-eager --load-format 'dummy'

# Run prompts in batch and save results to files.
vllm run-batch --input-file 'offline_inference/openai_batch/openai_example_batch.jsonl' --output-file 'results.jsonl' \
  --model 'meta-llama/Meta-Llama-3-8B-Instruct'
vllm run-batch --model 'meta-llama/Meta-Llama-3-8B-Instruct' -o 'results.jsonl' \
  -i 'https://raw.githubusercontent.com/vllm-project/vllm/main/examples/offline_inference/openai_batch/openai_example_batch.jsonl'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Use models pulled with Ollama.
# vLLM expects a Hugging Face model directory structure containing `config.json`, `tokenizer.json`, and other files, but
# Ollama stores models as a single blob files in GGUF format.
# vllm-metal (via MLX) cannot directly load a raw GGUF blob.
# FIXME: not working.
jq -r '.layers|sort_by(.size)[-1].digest|sub(":";"-")' \
  "$HOME/.ollama/models/manifests/registry.ollama.ai/library/codellama/13b" \
| xargs -pI '%%' \
    vllm serve "$HOME/.ollama/models/blobs/%%" --served-model-name 'codellama-13b' \
      --generation-config 'vllm' --tokenizer 'codellama/CodeLlama-13b-Instruct-hf' --load-format 'gguf'
```

</details>

## Further readings

- [Website]
- [Codebase]
- [Blog]
- Alternatives: [llama.cpp]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Language Models]: lms.md
[llama.cpp]: llama.cpp.md

<!-- Files -->
<!-- Upstream -->
[Blog]: https://blog.vllm.ai/
[Codebase]: https://github.com/vllm-project/
[Documentation]: https://docs.vllm.ai/en/
[vLLM-metal]: vllm-metal.md
[Website]: https://vllm.ai/

<!-- Others -->
