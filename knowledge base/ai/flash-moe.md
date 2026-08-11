# Flash-MoE

Inference engine that allows running frontier MoE models on consumer Apple Silicon by streaming their experts from SSD.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Inspired by Apple's [LLM in a Flash] research paper: since MoE LLMs have multiple experts per layer, but only a small
set of them is active per each token, an inference engine could keep in memory only the working set and load the
relevant experts from disk when needed.<br/>
The occupied memory would include a small fraction of the total model.

Written in C and Objective-C.

The entire model lives on SSD. Non-expert weights (attention, embeddings, shared expert) are always loaded in RAM.
The engine reads only the routed experts needed for the current token, on demand and in parallel.

Runs [Qwen3.5-397B-A17B][Qwen3.5] (397 billion parameters, 17 billion active per token) on a MacBook Pro with 48GB
unified memory at 4.36+ tokens per second, with production-quality output, and including tool calling.

Zero-framework design: no Python runtime for the engine, no BLAS libraries beyond Apple Accelerate, no external
dependencies.<br/>
Relies on the OS page cache for expert caching. This approach achieved a 71% cache hit rate and outperformed every
custom caching scheme tested across 58 documented experiments.

Key optimizations:

- FMA-optimized dequantization kernel, achieving a 12% throughput gain.
- Apple Accelerate BLAS results 64% faster than scalar loops.
- Deferred Metal command buffer submission lets GPU expert computation overlap with CPU routing for the next layer.
- Fused Metal kernels for 4/2-bit tiled matrix-vector multiply, SwiGLU activation, two-pass RMSNorm, GPU-native RoPE,
  batched attention, and MoE combine with residual.

Targets Apple Silicon **exclusively** (the Metal compute backend).<br/>
Requires fast NVMe SSD storage; the per-layer pipeline averages 4.28 ms at 4-bit, of which 2.41 ms is SSD I/O.

| Quantization | tok/s | Disk   | Quality   | Notes                                        |
| ------------ | ----- | ------ | --------- | -------------------------------------------- |
| 4-bit FMA    | 4.36  | 209 GB | Excellent | Production; full tool calling                |
| 4-bit base   | 3.90  | 209 GB | Excellent | Pre-FMA optimization                         |
| 2-bit        | 5.74  | 120 GB | Good      | Experimental; JSON and tool calling unstable |
| 2-bit peak   | 7.05  | 120 GB | Good      | Warm cache burst                             |

<details>
  <summary>Setup</summary>

Requires macOS on Apple Silicon.<br/>
Python is needed only for weight extraction and quantization scripts.

```sh
git clone 'https://github.com/danveloper/flash-moe' && cd 'flash-moe/metal_infer'
make
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Run inference.
./infer --prompt 'Explain quantum computing' --tokens 100

# 2-bit mode (faster, breaks tool calling).
./infer --prompt 'Explain quantum computing' --tokens 100 --2bit

# Interactive chat with tool calling support.
./chat

# Display per-layer timing breakdown.
./infer --prompt 'Hello' --tokens 20 --timing
```

</details>

## Further readings

- [Codebase]
- [LLM in a Flash] (Apple research paper, inspiration for the SSD streaming approach)
- Notable forks: [gorroai] (20.34 tok/s on M5 Max), [Anemll] (iOS port with Metal 4 NAX support)
- Alternatives: [Colibri], [llama.cpp], [vLLM]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Colibri]: colibri.md
[llama.cpp]: llama.cpp.md
[vLLM]: vllm.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/danveloper/flash-moe
[Qwen3.5]: https://huggingface.co/Qwen/Qwen3.5-397B-A17B

<!-- Others -->
[Anemll]: https://github.com/Anemll/flash-moe
[gorroai]: https://github.com/gorroai/flash-moe
[LLM in a Flash]: https://machinelearning.apple.com/research/efficient-large-language
