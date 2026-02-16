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
> One _can_ use [Claude Code router] or [Ollama] to run on a locally server or shared LLM instead.

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

<details>
  <summary>Usage</summary>

```sh
# Start in interactive mode.
claude

# Run a one-time task.
claude "fix the build error"

# Run a one-off task, then exit.
claude -p 'Hi! Are you there?'
claude -p "explain this function"

# Resume the most recent conversation that happened in the current directory
claude -c

# Resume a previous conversation
claude -r

# Add MCPs
claude mcp add --transport 'sse' 'linear-server' 'https://mcp.linear.app/sse'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Run Claude Code on a model served locally by Ollama.
ANTHROPIC_AUTH_TOKEN='ollama' ANTHROPIC_BASE_URL='http://localhost:11434' ANTHROPIC_API_KEY='' \
  claude --model 'lfm2.5-thinking:1.2b'
```

</details>

## Run on local models

Claude _can_ use other models and engines by setting the `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_BASE_URL` and
`ANTHROPIC_API_KEY` environment variables.

E.g.:

```sh
# Run Claude Code on a model served locally by Ollama.
ANTHROPIC_AUTH_TOKEN='ollama' ANTHROPIC_BASE_URL='http://localhost:11434' ANTHROPIC_API_KEY='' \
  claude --model 'lfm2.5-thinking:1.2b'
```

> [!warning]
> Performances do tend to drop substantially depending on the context size and the executing host.

<details style='padding: 0 0 1rem 1rem'>
  <summary>Examples</summary>

Prompt: `Hi! Are you there?`.<br/>
The model was run once right before the tests started to remove loading times.<br/>
Requests have been sent in headless mode (`claude -p 'prompt'`).

  <details style='padding: 0 0 0 1rem'>
    <summary><code>glm-4.7-flash:q4_K_M</code> on an M3 Pro MacBook Pro 36 GB</summary>

Model: `glm-4.7-flash:q4_K_M`.<br/>
Host: M3 Pro MacBook Pro 36 GB.<br/>
Claude Code version: `v2.1.41`.<br/>

| Engine             | Context | RAM usage | Used swap    | Average response time | System remained responsive |
| ------------------ | ------: | --------: | ------------ | --------------------: | -------------------------- |
| llama.cpp (ollama) |    4096 |     19 GB | No           |                   19s | No                         |
| llama.cpp (ollama) |    8192 |     19 GB | No           |                   48s | No                         |
| llama.cpp (ollama) |   16384 |     20 GB | No           |                2m 16s | No                         |
| llama.cpp (ollama) |   32768 |     22 GB | No           |                 7.12s | No                         |
| llama.cpp (ollama) |   65536 |     25 GB | No? (unsure) |                10.25s | Meh (minor stutters)       |
| llama.cpp (ollama) |  131072 |     33 GB | **Yes**      |                3m 42s | **No** (major stutters)    |

  </details>

</details>

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
- [pffigueiredo/claude-code-sheet.md]

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
[pffigueiredo/claude-code-sheet.md]: https://gist.github.com/pffigueiredo/252bac8c731f7e8a2fc268c8a965a963
