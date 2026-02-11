# vLLM

Open source library for LLM inference and serving.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Engineered specifically for high-performance, production-grade LLM inference.

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

```sh
pip install 'vllm'
pipx install 'vllm'
```

</details>

<details>
  <summary>Usage</summary>

```sh
vllm serve 'meta-llama/Llama-2-7b-hf' --port '8000' --gpu-memory-utilization '0.9'
vllm serve 'meta-llama/Llama-2-70b-hf' --tensor-parallel-size '2' --port '8000'
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
[Blog]: https://blog.vllm.ai/
[Codebase]: https://github.com/vllm-project/vllm
[Documentation]: https://docs.vllm.ai/en/
[Website]: https://vllm.ai/

<!-- Others -->
