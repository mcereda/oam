# LMStudio

Allows running LLMs locally.<br/>
Considered the most accessible tool for local LLM deployment, particularly for users with no technical background.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Focused on single-user scenarios without built-in rate limiting or authentication.

Offers highly mature and stable OpenAI-compatible API.

Supports full streaming, embeddings API, experimental function calling for compatible models, and limited multimodal
support.

Supports GGUF and Hugging Face Safetensors formats.<br/>
Has a built-in converter for some models, and can run split GGUF models.

Implements experimental tool calling support following the OpenAI function calling API format.<br/>
Models trained on function calling (e.g., Hermes 2 Pro, Llama 3.1, and Functionary) can invoke external tools through
the local API server. However, tool calling should **not** yet be considered suitable for production.<br/>
Streaming tool calls or advanced features like parallel function invocation are not currently supported.<br/>
Some models show better tool calling behavior than others.

The UI eases defining function schemas and test tool calls interactively

Considered ideal for:

- Beginners new to local LLM deployment.
- Users who prefer graphical interfaces over command-line tools.
- Developers needing good performance on lower-spec hardware (especially with integrated GPUs).
- Anyone wanting a polished professional user experience.

<details>
  <summary>Setup</summary>

```sh
brew install --cask 'lm-studio'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

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
[Blog]: https://lmstudio.ai/blog
[Codebase]: https://github.com/lmstudio-ai
[Documentation]: https://lmstudio.ai/docs/
[Website]: https://lmstudio.ai/

<!-- Others -->
