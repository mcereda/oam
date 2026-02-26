# Pi coding agent

Minimal, customizable, open source terminal coding harness.

Alternative to [Claude Code], [Gemini CLI] and [OpenCode].

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Using skills](#using-skills)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Meant to adapt to one's workflow.<br/>
Extensible with TypeScript extensions, skills, prompt templates, and themes.

Usable in _interactive_, _print/JSON_, _RPC_, and _SDK_ mode.

Leverages any inference engine and model as a service.<br/>
Authenticates via API keys or OAuth if needed.

Executes in YOLO mode by default.

Add custom providers and models via `models.json` or extensions.

Stores sessions as trees.<br/>
All branches live in a single file. Filter by message type, label entries as bookmarks.

Comes with a _minimal_ 200 tokens system prompt.<br/>
Allows control of what goes into the context window and how it's managed.

<details>
  <summary>Setup</summary>

Use `AGENTS.md` for project instructions, conventions, common commands. All matching files are _concatenated_.<br/>
Loads it (fallbacks to `CLAUDE.md`) at startup from:

- `~/.pi/agent/AGENTS.md` (global)
- Parent directories (walking up from cwd)
- Current directory

Replace the default system prompt with `.pi/SYSTEM.md` (in project) or `~/.pi/agent/SYSTEM.md` (global).<br/>
Append without replacing via `APPEND_SYSTEM.md` at the same locations.

Packages install to `~/.pi/agent/git/` (for git-based ones) or global `npm`.<br/>
Use `-l` for project-local installations (`.pi/git/`, `.pi/npm/` in project).

```sh
# Install.
npm install -g '@mariozechner/pi-coding-agent'
```

</details>

<details>
  <summary>Usage</summary>

| Command       | Hot key     | Action                                                                                 |
| ------------- | ----------- | -------------------------------------------------------------------------------------- |
| `/model`      | `Ctrl+L`    | Switch models mid-session                                                              |
| `/tree`       |             | Navigate to previous sessions' points                                                  |
| `/export`     |             | Export sessions to HTML                                                                |
| `/share`      |             | Upload a session to a GitHub gist and get a shareable URL that renders it              |
|               | `Ctrl+P`    | Cycle through favorites                                                                |
|               | `Enter`     | Send a steering message (delivered after the current tool, interrupts remaining tools) |
|               | `Alt+Enter` | Send a follow-up (waits until the agent finishes)                                      |
| `/skill:name` |             | Invoke a skill                                                                         |

```sh
# Run interactively.
pi
pi "Some initial prompt"
pi --provider openai --model gpt-4o "Help me refactor"

# Run in read-only mode
pi --tools 'read,grep,find,ls' -p "Review the code"

# High thinking level
pi --thinking 'high' "Solve this complex problem"

# Run headless.
pi -p "query"

# Output all events as JSON lines to allow for event streams.
pi --mode 'json'

# List packages.
pi list

# Install packages.
pi install npm:@foo/pi-tools
pi install npm:@foo/pi-tools@1.2.3            # pinned version
pi install git:github.com/user/repo
pi install git:github.com/user/repo@v1        # tag or commit
pi install git:git@github.com:user/repo
pi install git:git@github.com:user/repo@v1    # tag or commit
pi install https://github.com/user/repo
pi install https://github.com/user/repo@v1    # tag or commit
pi install ssh://git@github.com/user/repo
pi install ssh://git@github.com/user/repo@v1  # tag or commit

# Update packages.
# Skips pinned ones.
pi update

# Enable or disable packages.
pi config

# Test packages without installing them.
pi -e 'git:github.com/user/repo'

# Remove packages.
pi remove 'npm:@foo/pi-tools'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Using skills

Skills shall follow the [Agent Skills] standard.

Place skills in `~/.pi/agent/skills/`, `~/.agents/skills/`, `.pi/skills/`, or `.agents/skills/` (from cwd up through
parent directories), or in a pi package to share with others.

Invoke them via `/skill:name`, or let the agent load them automatically.

## Further readings

- [Website]
- [Codebase]
- [What I learned building an opinionated and minimal coding agent]

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
[OpenCode]: opencode.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/badlogic/pi-mono
[Documentation]: https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent#readme
[Website]: https://pi.dev

<!-- Others -->
[Agent Skills]: https://agentskills.io/
[What I learned building an opinionated and minimal coding agent]: https://mariozechner.at/posts/2025-11-30-pi-coding-agent/
