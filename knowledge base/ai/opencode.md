# OpenCode

> TODO

Open source AI coding agent.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

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
        }
      }
    }
  }
}
```

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

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/anomalyco/opencode
[Documentation]: https://opencode.ai/docs
[Website]: https://opencode.ai

<!-- Others -->
