# OpenCode

Open source AI coding agent.

Alternative to [Claude Code], [Gemini CLI] and [Pi].

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Includes LSP integration and automatically configures language servers for the LLM.<br/>
Supports running multiple parallel agents on the same project (_multi-session_), and sharing sessions via links.<br/>
Stores **no** code or context data.<br/>
Supports multiple model providers (Models.dev. Claude, GPT, Gemini, local servers).<br/>
Includes free models by default.

<details>
  <summary>Setup</summary>

```sh
# Install
brew install 'anomalyco/tap/opencode'  # or 'opencode'
docker run -it --rm 'ghcr.io/anomalyco/opencode'
mise use -g 'opencode'
nix run 'nixpkgs#opencode'
npm i -g 'opencode-ai@latest'
pacman -S 'opencode'
paru -S 'opencode-bin'

# Desktop app
brew install --cask 'opencode-desktop'
```

Configure OpenCode using `opencode.json` (or `.jsonc`) configuration files.<br/>
Configuration files are merged, not replaced. Settings from more specific ones override those of the same name in less
specific ones.

| Scope   | Location                                        | Summary                   |
| ------- | ----------------------------------------------- | ------------------------- |
| Remote  | `.well-known/opencode`                          | organizational defaults   |
| Global  | `~/.config/opencode/opencode.json`              | user preferences          |
| Custom  | `OPENCODE_CONFIG` environment variable          | custom overrides          |
| Project | `opencode.json` in the project's directory      | project-specific settings |
| Agent   | `.opencode` directories                         | agents, commands, plugins |
| Inline  | `OPENCODE_CONFIG_CONTENT` environment variables | runtime overrides         |

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "llama2": {
          "name": "Llama 2"
        },
        "qwen3-coder:30b-32k": {
          "name": "Qwen3 Coder 30B",
          "limit": {
            "context": 32768,
            "output": 4096
          }
        }
      }
    }
  }
}
```

> [!warning]
> The `provider.*.models.*.limit.context` setting appear to be currently used only to control when the compaction
> triggers. It does **not** signal the context size to the provider.<br/>
> OpenCode connects to [Ollama] via the OpenAI-compatible `/v1` endpoint, which has **no** `num_ctx` parameter. Context
> must be controlled on the Ollama side by:
>
> 1. Creating a Modelfile variant (most reliable, creates a configuration pointing to the same weights at no disk cost).
>
>    <details style='padding: 0 0 1rem 1rem'>
>
>    ```sh
>    ollama create model-32k --from model:tag --set "parameter num_ctx=32768"
>    ```
>
>    <details>
>
> 1. Setting the `OLLAMA_CONTEXT_LENGTH=32768` environment variable.<br/>
>    This affects **all** served models. May be overridden by VRAM auto-detection in newer Ollama versions.
>
> Without this, Ollama [auto-sizes context based on available VRAM][ollama / context auto-sizing], which on
> Apple Silicon machines with >= 48 GiB unified memory silently allocates 262k tokens, consuming most of the available
> memory.

</details>

<details>
  <summary>Usage</summary>

```sh
# Start in interactive mode.
opencode
opencode 'path/to/directory'

# List available models.
opencode models
opencode models 'anthropic'

# Update the cashed models list.
opencode models --refresh

# Run tasks in headless mode.
opencode run "Explain how closures work in JavaScript"

# Start a headless server.
opencode serve

# Attach to headless servers.
opencode run --attach 'http://localhost:4096' "Explain async/await in JavaScript"

# List existing agents.
opencode agent list
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
- [Claude Code]
- [Gemini CLI]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Claude Code]: claude/claude%20code.md
[Gemini CLI]: gemini/cli.md
[Ollama / context auto-sizing]: ollama.md#gotchas
[Ollama]: ollama.md
[Pi]: pi.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/anomalyco/opencode
[Documentation]: https://opencode.ai/docs
[Website]: https://opencode.ai

<!-- Others -->
