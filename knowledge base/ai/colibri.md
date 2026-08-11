# Colibri

Inference engine written in pure C to run frontier MoE models on consumer hardware.<br/>
Treats VRAM, RAM, and disk as one managed memory hierarchy, streaming routed experts from storage on demand.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Enables _local_ execution of frontier-scale [Mixture-of-Experts models][Language Models] that use hundreds of billions
to trillions of parameters.

Zero-dependency design: no BLAS library, no GPU required, no Python runtime for the engine itself.<br/>
The engine is a single C file with OpenMP parallelization.

Uses its own container format for quantized model distribution.<br/>
Dense model components (attention, embeddings, shared experts) stay resident in RAM at int4 quantization. Routed experts
live on disk and stream on demand.

Processes each token through five sequential stages (route, union, place, overlap, learn) to ensures that router
decisions and weight precision remain identical regardless of where an expert resides.

Expert caching uses a per-layer LRU. Prefetch hides staging latency.<br/>
Records routing patterns across sessions in a persistent `.coli_usage` file to make the engine faster with continued
use. Frequently accessed experts earn better placement.

Compresses the KV cache 57x smaller (576 floats per token instead of 32,768) to allow making long-context inference
feasible on limited RAM.<br/>
Enables warm session reopening using a persistent conversation state (`.coli_kv` files).

Supports:

- Native MTP (multi-token prediction) speculative decoding with grammar-forced drafts.
- CPU (OpenMP), CUDA, Metal (Apple Silicon), and Vulkan (AMD, NVIDIA, Intel, and legacy GPUs without vendor driver
  support) as backends.<br/>
- Dual-SSD configurations for **aggregate** reads across drives.

Exposes an OpenAI-compatible API server with a web dashboard for real-time metrics.

| Model     | Parameters | Active | Notes                                           |
| --------- | ---------- | ------ | ----------------------------------------------- |
| GLM-5.2   | 744B       | 40B    | Reference implementation                        |
| [Inkling] | 975B       | 41B    | bf16 dense, int4 experts                        |
| Kimi K3   | 2.8T       | 104B   | Preview; native MXFP4, full generation untested |
| OLMoE     | 7B         | 1B     | Converted to int4                               |

<details>
  <summary>Setup</summary>

Requires Python 3 for the launcher and API gateway only.

```sh
# Prebuilt releases available for Linux, macOS, and Windows.
# Download from GitHub Releases and extract.
mkdir -p path/to/colibri && cd path/to/colibri \
&& curl -fsLS 'https://github.com/JustVugg/colibri/releases/download/v1.4.0/colibri-v1.4.0-macos-arm64.tar.gz' | tar -xv

# From source.
# Requires gcc/clang with OpenMP.
git clone 'https://github.com/JustVugg/colibri' && cd 'colibri/c'
./setup.sh

# Download reference models from Hugging Face (e.g. GLM-5.2, 372 GB container).
# Easier to use Hugging Face's CLI.
hf download 'mastouri/GLM-5.2-colibri-int4-g64-with-int8-mtp' --local-dir '/path/to/glm52'

# Convert models from FP8 source.
./coli convert --model '/path/to/glm52'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Set the model.
export COLI_MODEL='/path/to/model'

# Diagnostics and tuning.
./coli plan     # inspect VRAM/RAM/disk placement
./coli doctor   # readiness check
./coli tune     # profile and save fastest safe configuration

# Start interactive chats.
./coli chat

# Start in server modes.
./coli serve --model '/path/to/model'   # OpenAI-compatible API only
./coli web --model '/path/to/model'     # serve + open web dashboard
```

</details>

## Further readings

- [Website]
- [Codebase]
- Alternatives: [Flash-MoE], [llama.cpp], [vLLM]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Flash-MoE]: flash-moe.md
[Language Models]: lms.md
[llama.cpp]: llama.cpp.md
[vLLM]: vllm.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/JustVugg/colibri
[Inkling]: https://huggingface.co/blog/thinkingmachines-inkling
[Website]: https://justvugg.github.io/colibri/

<!-- Others -->
