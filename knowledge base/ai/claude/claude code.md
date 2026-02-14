# Claude Code

> TODO

[Agentic][ai agent] coding tool that reads and edits files, runs commands, and integrates with tools.<br/>
Works in a terminal, IDE, browser, and as a desktop app.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Run on local models](#run-on-local-models)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

> [!warning]
> Normally requires an Anthropic account to be used.<br/>
> One _can_ use [Claude Code router] or [Ollama] to run on a locally server or shared LLM instead, but its performances
> do seem to take an extreme hit.

Uses a scope system to determine where configurations apply and who they're shared with.<br/>
When multiple scopes are active, the **more** specific ones take precedence.

| Scope                   | Location                             | Area of effect                     | Shared                                    |
| ----------------------- | ------------------------------------ | ---------------------------------- | ----------------------------------------- |
| Managed (A.K.A. System) | System-level `managed-settings.json` | All users on the host              | Yes (usually deployed by IT)              |
| User                    | `~/.claude/` directory               | Single user, across all projects   | No                                        |
| Project                 | `.claude/` directory in a repository | All collaborators, repository only | Yes (usually committed to the repository) |
| Local                   | `.claude/*.local.*` files            | Single user, repository only       | No (usually gitignored)                   |

<details>
  <summary>Setup</summary>

```sh
brew install --cask 'claude-code'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<details>
  <summary>Real world use cases</summary>

```sh
# Run Claude Code on a model served locally by Ollama.
ANTHROPIC_AUTH_TOKEN=ollama ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY="" claude --model 'lfm2.5-thinking:1.2b'
```

</details>

## Run on local models

Performance examples:

| Engine             | Model                | Context (tokens) | Size in RAM | Executing host           | Average time to respond to `Hi!` |
| ------------------ | -------------------- | ---------------- | ----------- | ------------------------ | -------------------------------- |
| llama.cpp (ollama) | glm-4.7-flash:q4_K_M | 4096             | 19 GB       | M3 Pro MacBook Pro 36 GB | 59 s                             |
| llama.cpp (ollama) | glm-4.7-flash:q4_K_M | 8192             | 19 GB       | M3 Pro MacBook Pro 36 GB | 52 s                             |

## Further readings

- [Website]
- [Codebase]
- [Blog]
- [AI agent]
- [Claude Code router]
- [Gemini CLI]
- [OpenCode]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[AI agent]: ../agent.md
[Claude Code router]: claude%20code%20router.md
[Gemini CLI]: ../gemini/cli.md
[Ollama]: ../ollama.md
[OpenCode]: ../opencode.md

<!-- Files -->
<!-- Upstream -->
[Blog]: https://claude.com/blog
[Codebase]: https://github.com/anthropics/claude-code
[Documentation]: https://code.claude.com/docs/en/overview
[Website]: https://claude.com/product/overview

<!-- Others -->
