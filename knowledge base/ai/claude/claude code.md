# Claude Code

[Agentic][ai agents] harness around [Claude] providing it with tools, context management, and execution
environment.<br/>
Works in a terminal, IDE (via plugin), and in Claude's desktop app.

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
   1. [Credentials](#credentials)
1. [Context and memory](#context-and-memory)
   1. [Giving Claude its own knowledge base](#giving-claude-its-own-knowledge-base)
1. [Using tools](#using-tools)
   1. [Managing MCP servers](#managing-mcp-servers)
   1. [Limit tool execution](#limit-tool-execution)
1. [Using skills](#using-skills)
1. [Using plugins](#using-plugins)
1. [Using hooks](#using-hooks)
   1. [Prompt-based hooks](#prompt-based-hooks)
   1. [Agent-based hooks](#agent-based-hooks)
   1. [HTTP hooks](#http-hooks)
1. [Delegating work](#delegating-work)
   1. [Subagents](#subagents)
   1. [Agent teams](#agent-teams)
   1. [MCP servers in sub-agents](#mcp-servers-in-sub-agents)
1. [Scheduling tasks](#scheduling-tasks)
1. [Tools of interest](#tools-of-interest)
1. [Best practices](#best-practices)
1. [Run on local models](#run-on-local-models)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

Can run in multiple isolated shell sessions.<br/>
Prefer using [git worktrees] to isolate sessions running within the same repository.

Can access and understand images and other file types, read and edit files, run commands and tools, and do all of that
in parallel.

_Normally_:

- Tied to Anthropic's Claude models (Haiku, Sonnet and Opus).
- Requires a Claude API key or Anthropic plan.<br/>
  Usage is metered by the token.

> [!tip]
> One _can_ route requests to other services using [Claude Code router], or use local models with [Ollama].<br/>
> Performances do take a _major_ hit, though.

Uses a **scope** system to determine where configuration files apply, and who they're shared with.<br/>
Configuration is loaded and **merged** in the following order:

```mermaid
flowchart LR
  u("User") --> p("Project") --> l("Local") --> e("Execution environment") --> m("Managed")
```

Use _settings.json_ files for permissions, hooks, env vars, etc.<br/>
[`settings.json` file example][settings.json file example].

Use _.mcp.json_ files for project-level MCP definitions.<br/>
[`.mcp.json` file example][.mcp.json file example].

Store _other_ configuration like personal preferences (theme, notification settings, editor mode), OAuth session, MCP
server configurations for user and local scopes, per-project state (allowed tools, trust settings), and various caches
in `~/.claude.json`.<br/>
Updated _autonomously_ by Claude Code. Prefer **not** editing this file manually.<br/>
**Not** part of the `settings.json` hierarchy as much as a runtime state file.<br/>

Supports a **plugin** system for extending its capabilities.

Sends Statsig telemetry data by default. Includes operational metrics (latency, reliability, usage patterns).<br/>
Disable it by setting the `DISABLE_TELEMETRY` environment variable to `1`.

> [!tip]
> Gives better results when asked to _plan_ before writing code, and then _iterates_ on it.

Common workflows:

- Explore, plan, ask for confirmation, write code, commit.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example</summary>

  > Figure out the root cause for issue #43, then propose possible fixes.<br/>
  > Let me choose an approach before you write code.<br/>
  > Think fast.

  </details>

- Write tests, commit, write code, iterate, commit, push, create a PR.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example</summary>

  > Write tests for @utils/markdown.ts to make sure links render properly.<br/>
  > Note these tests will not pass yet since links are not yet implemented.<br/>
  > Commit.<br/>
  > Update the code to make the tests pass.<br/>
  > Commit. Push. PR.

  </details>

- Write code, screenshot the result, track progress, iterate.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example</summary>

  > Implement \[mock.png], then screenshot it with Puppeteer and iterate until it looks like the mock.<br/>
  > Write down notes for yourself at every iteration. Think hard.

  </details>

Hit `esc` **once** to stop Claude.<br/>
This action is _usually_ safe. Claude will then resume or try a different approach, while retaining context about the
previous request.

Refer to [Claude] for details on models and usage.

Prefer using **Sonnet** for quicker, smaller tasks (e.g. as sub-agent, greenfield coding, app initialization).<br/>
Consider using **Opus** for broader, longer, higher-level tasks (e.g. planning, refactoring, orchestrating
sub-agents).<br/>
Consider using **Haiku** for quick responses.

The `opusplan` mode allows using Opus during planning, then automatically switches to Sonnet for implementation.

Change how Claude responds (without affecting its capabilities) by configuring an [output style][output styles].<br/>
The builtin `explanatory` style adds educational insights between tasks; `learning` shares insights _and_ asks the user
to contribute to changes.<br/>
Custom styles can be created as Markdown files in the `~/.claude/output-styles/` and `.claude/output-styles/` folders.

Use memory and context files (`CLAUDE.md`) to instruct Claude Code on commands, style guidelines, and give it _key_
context. Try to keep them small.

Consider allowing specific tools to reduce interruption and avoid fatigue due to too many requests.<br/>
Prefer using CLI tools over MCP servers as they are generally faster, don't require a running server, and have usually
lower overhead.

Make sure to use `/clear` or `/compact` regularly to allow Claude to maintain focus on the conversation.<br/>
Or ask it to create notes to self and restart it once the context goes above a threshold (usually best at 60%).

<details>
  <summary>Setup</summary>

See also [Configuration] and [Environment variables][environment variables reference].

```sh
# Install.
brew install --cask 'claude-code'
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://claude.ai/install.sh | bash -s 'stable'
curl -fsSL https://claude.ai/install.sh | bash -s '2.1.74'
npm install -g '@anthropic-ai/claude-code'  # deprecated, prefer others

# Check installation and configuration.
claude --version
claude doctor

# Uninstall.
brew uninstall --zap 'claude-code'
npm uninstall -g '@anthropic-ai/claude-code'
rm -rf "$HOME/.local/bin/claude" "$HOME/.local/share/claude"

# Cleanup settings.
rm -rf "$HOME/.claude" "$HOME/.claude.json" ".claude" ".mcp.json"
```

</details>

<details>
  <summary>Usage</summary>

Refer to [CLI reference].

```sh
# Start in interactive mode.
# Best to start from a repository.
claude

# Run a one-time task.
claude "fix the build error"

# Run a one-off task, then exit.
claude -p 'Hi! Are you there?'
claude -p "explain the function in @someFunction.ts"
claude -p 'What did I do this week?' --allowedTools 'Bash(git log*)' --output-format 'json'
cat 'minutes.md' | claude -p "summarize this"

# Resume the most recent conversation that happened in the current directory
claude -c

# Resume a previous conversation
claude -r

# Add MCP servers.
# Defaults to the 'local' scope if not specified.
claude mcp add --transport 'http' 'GitLab' 'https://some.local.gitlab.com/api/v4/mcp'
claude mcp add --transport 'http' 'linear' 'https://mcp.linear.app/mcp' --scope 'user'

# List installed MCP servers.
claude mcp list

# Show MCP servers' details
claude mcp get 'github'

# Remove MCP servers.
claude mcp remove 'github'

# Load local plugins.
claude --plugin-dir './path/to/plugin'

# Install plugins.
# Marketplace defaults to 'claude-plugins-official'.
# Scope defaults to 'user'.
claude plugin install 'gitlab'
claude plugin i 'aws-cost-saver@aws-cost-saver-marketplace' --scope 'project'

# List installed plugins only.
claude plugin list

# List all plugins.
claude plugin list --available --json

# Enable plugins.
claude plugin enable 'gitlab@claude-plugins-official'

# Disable plugins.
claude plugin disable 'gitlab@claude-plugins-official'

# Update plugins.
claude plugin update 'gitlab@claude-plugins-official'
```

_Relevant_ commands from within Claude Code (version 2.1.89).<br/>
Refer to [Built-in commands][built-in commands reference] for the complete list.

```plaintext
/agents                              Manage agent configurations
/batch <instruction>                 Research and plan a large-scale change, then execute it in parallel across 5 to 30 isolated worktree agents that each open a PR
/branch [name]                       Create a branch of the current conversation at this point (alias of /fork)
/btw <question>                      Ask a quick side question without adding to the conversation
/clear                               Clear conversation history and free up context (alias of /reset and /new)
/compact [instructions]              Compact the conversation; allows optional focus instructions
/config                              Open config panel (alias of /settings)
/context                             Visualize current context usage as a colored grid
/copy [N]                            Copy Claude's last response or a code block to clipboard
/cost                                Show token usage statistics
/debug [description]                 Enable debug logging for this session and help diagnose issues
/diff                                View uncommitted changes and per-turn diffs
/effort [low|medium|high|max|auto]   Set effort level for model usage
/exit                                Exit the REPL (alias of /quit)
/export [filename]                   Export the current conversation to a file or clipboard
/fast [on|off]                       Toggle fast mode (Opus only)
/help                                Show help and available commands
/hooks                               Manage hook configurations for tool events
/init                                Initialize a new CLAUDE.md file with codebase documentation
/insights                            Generate a report analyzing Claude Code sessions
/login                               Sign in with your Anthropic account
/logout                              Sign out from your Anthropic account
/loop [interval] <prompt>            Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo, defaults to 10m)
/mcp                                 Manage MCP servers
/memory                              Edit Claude memory files
/model [model]                       Set the AI model for Claude Code
/permissions                         Manage allow, ask, and deny tool permission rules (alias of /allowed-tools)
/plan [description]                  Enable plan mode or view the current session plan
/plugin                              Manage Claude Code plugins
/reload-plugins                      Activate pending plugin changes in the current session
/rename [name]                       Rename the current conversation
/resume [session]                    Resume a previous conversation (alias of /continue)
/rewind                              Restore the code and/or conversation to a previous point (alias of /checkpoint)
/sandbox                             Toggle sandbox mode
/security-review                     Complete a security review of the pending changes on the current branch
/simplify [focus]                    Review changed code for reuse, quality, and efficiency, then fix any issues found
/skills                              List available skills
/status                              Show version, model, account, and connectivity status
/tasks                               List and manage background tasks (alias of /bashes)
/usage                               Show plan usage limits
/voice                               Toggle push-to-talk voice dictation
```

</details>

<details style='padding: 0 0 1rem 0'>
  <summary>Real world use cases</summary>

```sh
# Run Claude Code on a model served locally by Ollama.
ollama launch claude --model 'lfm2.5-thinking:1.2b'
ANTHROPIC_AUTH_TOKEN='ollama' ANTHROPIC_BASE_URL='http://localhost:11434' ANTHROPIC_API_KEY='' \
  claude --model 'lfm2.5-thinking:1.2b'
```

</details>

## Configuration

Refer to [Settings][documentation / settings].

Claude Code uses a **scope system** to determine where configuration files apply, and with what precedence.

The _user_ scope applies to **all** projects, but only for the **active** user.

The _project_ scope applies to **all contributors**, but only in the **active** project.<br/>
Meant for **shared** settings, preferences, tools and plugins the whole team should have. It is usually the best scope
to standardize them across collaborators.

The _local_ scope affects only the **active** user across a **single** project.<br/>
Meant to specify personal overrides for specific projects.

The _managed_ scope affects **all** contributors across **all** projects.<br/>
Meant for organization-wide policies, compliance requirements and standardized configurations that **must** be enforced
and that should **not** be overridden.

```mermaid
---
title: Scope's merge priority
---
flowchart LR
  m("Managed") -- overrides --> e("Execution environment")
  e -- overrides --> l("Local")
  l -- overrides --> p("Project")
  p -- overrides --> u("User")
```

Files:

| Feature     | User files                | Project files                       | Local files                                         | Managed files           |
| ----------- | ------------------------- | ----------------------------------- | --------------------------------------------------- | ----------------------- |
| Settings    | `~/.claude/settings.json` | `.claude/settings.json`             | `.claude/settings.local.json`                       | `managed-settings.json` |
| Subagents   | `~/.claude/agents/`       | `.claude/agents/`                   | None                                                | FIXME                   |
| MCP servers | `~/.claude.json`          | `.mcp.json`                         | `~/.claude.json`, under `projects.{{project.path}}` | `managed-mcp.json`      |
| Plugins     | `~/.claude/settings.json` | `.claude/settings.json`             | `.claude/settings.local.json`                       | FIXME                   |
| `CLAUDE.md` | `~/.claude/CLAUDE.md`     | `CLAUDE.md`<br/>`.claude/CLAUDE.md` | None                                                | FIXME                   |

_Settings_ like permissions, hooks, environment variables, etc. should reside in `settings.json`-like files.<br/>
The [settings' schema] is available on schemastore.org.<br/>
[`settings.json` file example][settings.json file example].

_MCP servers_ are defined **separately** from settings.<br/>
Use `.mcp.json`-like files at the project scope or in `~/.claude.json`.<br/>
[`.mcp.json` file example][.mcp.json file example].

_Other_ configuration is stored in `~/.claude.json`.<br/>
It's **not** part of the `settings.json` hierarchy as much as a runtime state file, though _some_ settings are accepted
and loaded for backwards compatibility.<br/>
It contains _preferences_ (theme, notification settings, editor mode), OAuth session, MCP server configurations for user
and local scopes, per-project state (allowed tools, trust settings), and caches.<br/>
`~/.claude.json` is meant to be managed _autonomously_ by Claude Code. Commands like `claude mcp add` update it via
Claude Code. Prefer **not** editing this file manually.<br/>

> [!tip]
> Run `/status` from inside Claude Code to see which settings sources are active and where they come from.

See also [Configuration] and [Environment variables][environment variables reference].

### Credentials

Depending on one's OS and authentication method:

- **OAuth credentials** (e.g., GitHub, remote MCP servers) are stored in the system keychain on macOS, or in a
  credentials file on other platforms.
- General **authentication tokens and credentials file** are stored in the system keychain on macOS and in
  `~/.claude/.credentials.json` on Linux and Windows.
- **API keys** should be passed as environment variables to MCPs (e.g. `--env API_KEY=...` when adding one via
  `claude mcp add`) or saved manually in `~/.claude.json`.

| Platform | Credential Location                                             |
| -------- | --------------------------------------------------------------- |
| macOS    | System Keychain (`Keychain Access.app → login → "Claude Code"`) |
| Linux    | `~/.claude/.credentials.json`                                   |
| Windows  | `%USERPROFILE%\.claude\.credentials.json`                       |

[`~/.claude/credentials.json` file example][~/.claude/credentials.json file example].

## Context and memory

Refer to:

- [AI agents context and memory][ai agents / context and memory]
- [Manage Claude's memory].

> [!important]
> Every session begins with a fresh context window.

Claude Code uses `CLAUDE.md` as its context file.<br/>
Its purpose is to apply _procedural memories_ and other _recurrent_ context at the start of sessions.<br/>
It should only contain instructions, rules, and preferences; **avoid** memories related to other sessions.<br/>
One _can_ ask Claude to write and/or update this file on their behalf.

> [!important]
> Claude is instructed in its system prompt to **intentionally** ignore `CLAUDE.md` instructions that it deems
> irrelevant to the current task.

`CLAUDE.md` files can _import_ additional files using the `@path/to/import` syntax. This is currently an exclusive
feature of Claude Code.<br/>
Imported files are expanded and loaded into context at launch, alongside the `CLAUDE.md` file referencing them.<br/>
It allows both relative and absolute paths. Relative paths resolve relative to **the file containing the import**, not
to the current working directory.<br/>
Imported files _can_ recursively import other files up to 5 hops.

<details style='padding: 0 0 1rem 1rem'>

Pull in a README, package.json, or workflow guide by referencing them with the `@` syntax anywhere in a `CLAUDE.md`
file:

```md
See @README for project overview, and @package.json for available npm commands for this project.

## Additional Instructions

- git workflow: @docs/git-instructions.md

## Individual Preferences

- @~/.claude/my-project-instructions.md
```

</details>

The **first** time Claude Code encounters external imports in a project, it shows an approval dialog listing the files.
If declined, the imports stay disabled and the dialog does **not** appear again.

Claude Code reads `CLAUDE.md` files by walking **up** the directory tree from the current working directory.<br/>
E.g., if it is running in `foo/bar/`, it loads instructions from both `foo/bar/CLAUDE.md` and `foo/CLAUDE.md`.

Block-level HTML comments (`<!-- … -->`) in `CLAUDE.md` files are **stripped** before injection into context. Use them to
leave notes for human maintainers without spending context tokens. Comments inside code blocks are preserved.

The `--add-dir` flag gives Claude access to additional directories outside the main working directory.<br/>
By default, `CLAUDE.md` files from those directories are **not** loaded. Set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`
to also load them.

Prefer using _rules_ for a more structured approach to organizing instructions.<br/>
Rules live in `.claude/rules/*.md` and are discovered _recursively_.

Rules **without** a `paths` frontmatter field are
loaded _unconditionally_ at launch.<br/>
Rules **with** a `paths` field _only_ load when Claude reads files matching the specified glob patterns:

<details style='padding 0 0 1rem 1rem'>

```yml
---
paths:
  - "src/api/**/*.ts"
---
```

</details>

Skip irrelevant `CLAUDE.md` files by using the `claudeMdExcludes` setting.

<details style='padding 0 0 1rem 1rem'>

```json
{
  "claudeMdExcludes": [
    "**/some-repo/CLAUDE.md",
    "/home/user/some-repo/some-section/.claude/rules/**"
  ]
}
```

</details>

Claude Code can save learnings, patterns, and insights gained during active sessions, and load them in later sessions
by maintaining `~/.claude/projects/<project>/memory/MEMORY.md` files.<br/>
The first 200 lines or 25 KB (whichever comes first) of those files are loaded at the start of every session. Consider
using `MEMORY.md` as an index, and move detailed notes into topic-specific files for Claude Code to load on demand.

When _auto memory_ is enabled, Claude Code _should™_ automatically update memory files.<br/>
It is enabled by default. Disable it via the `/memory` toggle, `settings.json`, or
`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.<br/>
Store auto memory in custom locations by setting `autoMemoryDirectory` in user or local-level settings. Avoid doing
this in project-level settings to prevent redirecting memory writes to sensitive locations.

Subagents can maintain their own auto memory. Refer to [subagent memory configuration].

Also see [thedotmack/claude-mem] for an automatic memory management system.

Memory files' loading order:

| Scope          | Type                | Location                                                                                             | Notes                                                 |
| -------------- | ------------------- | ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| Managed        | Enterprise policy   | `/etc/claude-code/CLAUDE.md` (Linux)<br/>`/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS) | Loaded in full at launch                              |
| User           | Context file        | `~/.claude/CLAUDE.md`                                                                                | Loaded in full at launch                              |
| Project        | Shared context file | `./CLAUDE.md` or `./.claude/CLAUDE.md`                                                               | Loaded in full at launch                              |
| Project        | Rules               | `./.claude/rules/*.md`                                                                               | Loaded in full at launch                              |
| Subdirectory   | Context file        | `<project>/some-subdir/CLAUDE.md`                                                                    | Loaded on demand when reading files in this directory |
| Active session | Auto memory         | `~/.claude/projects/<project>/memory/`                                                               | Complement the context without overriding             |

More specific files override broader ones on conflicting instructions, but they **merge** together and do **not**
replace each other.<br/>
Managed policy files **cannot** be excluded. Organization-wide rules **always apply regardless**.

Files at the same scope level should **not** conflict with each other, only define instructions for specific
domains.<br/>
Combine conflicting rules into a single file, or leverage the hierarchy to handle precedence.

Key commands:

| Command   | Summary                                              |
| --------- | ---------------------------------------------------- |
| `/memory` | View, edit, or toggle auto memory on/off             |
| `/init`   | Bootstrap a `CLAUDE.md` file for the current project |

Use the [`InstructionsLoaded` hook][instructionsloaded hook] to log exactly which instruction files are loaded, when
they load, and why.<br/>
Useful for debugging path-specific rules or lazy-loaded files in subdirectories.

It appears Claude (at least the 4.6 suite) follows instructions better when given with an _imperative_ tone.<br/>
Prefer writing important instructions that way.

When a rule applies **conditionally**, state the **negative** case **explicitly**. Positive patterns are stronger
than embedded conditionals.<br/>
Fast models prefer pattern-matching instead of reasoning. Them seeing the positive pattern may apply it everywhere.
Adding a negative example gives the model a concrete off-ramp instead of an inferred one.

Creating a good `CONTRIBUTING.md` file, and mandating Claude Code to read it before making changes, seems to go a long
way for **both** humans and agents.

It appears Claude works better when treated as part of the team.<br/>
And as part of the team, it is right for it to have a chance to contribute to processes.

> Please check the `CONTRIBUTING.md` file is helpful to _you_, and eventually suggest improvements to allow _you_ to
> contribute better.<br/>
> The goal is to give _you_ all the information _you_ need about the workflow, without needing to put extra information
> in the `CLAUDE.md` file.

> [!tip]
> Iterate on this for at least a couple of times and a couple of different sessions for the best results.

Consider also asking it to keep the files up to date using notes and findings from the session:

> I changed the file structure to make it adhere more to the standards we shoot for. Please check my changes and take
> notes for yourself. Also please share those takeaways in the `CONTRIBUTING.md` file.

> [!tip]
> Consider using [hooks][using hooks] if specific actions **need** to happen, and should not rely on Claude _deciding_
> to take them.

<details>
  <summary>Example of CLAUDE.md file implementing the suggestions</summary>

```md
# CLAUDE.md

> [!important] Claude Code self-reminders — MANDATORY, follow for every change
>
> 1. **Before making or suggesting any changes, read `CONTRIBUTING.md`**. Pay extra attention to the code organization
>    and conventions.
> 1. **Follow closely the workflow in `CONTRIBUTING.md § Submitting changes`**.
> 1. **Review and offer to update `CONTRIBUTING.md`** to share _relevant_ notes and findings with the team. Insist on
>    this if you make changes.
> 1. **Review and offer to update `CLAUDE.md`** with relevant information _for you_ that would not duplicate the content
>    of `CONTRIBUTING.md`.

## Overview
…
```

</details>

People are showing success _delegating_ this work to Claude at the start of a project.<br/>
Consider delegating ownership of tools and documentation to Claude early in a project, making it responsible for the
tools and documents it creates _and_ uses. Also include in the request to periodically to check and update those files
to correct its own behavior across sessions.

### Giving Claude its own knowledge base

It works better when:

- Claude Code does **not** need to ask for permissions when operating on it.

  Project-level permission setting like `Bash` and `Edit(/**)` scope allowances to the KB's specific project when making
  changes from inside of it. Configuring `defaultMode` to `auto` or `dontAsk` avoids approval requests for those
  actions.<br/>
  User-level setting like `Bash(git -C ~/Repositories/claude/kb *)` and `Edit(~/Repositories/claude/kb/**)` scope
  allowances to the KB's specific directory when making changes from other projects.<br/>

  > [!tip]
  > Remember to add `rtk`-related permissions if using [rtk-ai/rtk], e.g. `Bash(rtk git -C ~/Repositories/claude/kb *)`.

- Claude Code is _consistently_ remembered to update it.<br/>
  A `command` type `UserPromptSubmit` hook seems to be currently the best option.
- The KB is its own **local** git repository.<br/>
  It does kinda work using a GitLab or confluence wiki _directly_, but the process to update pages in it via API is
  expensive and slow. Git repositories are local, better for agents to manage, and just a `git push` away from online
  backup.

> [!note]
> Procedure modelled after [karpathy/llm-wiki.md], because leveraging ready-to-use instructions just makes things
> easier.

1. Create a git repository for Claude's knowledge base:

   ```sh
   git init "$HOME/path/to/claude/kb"
   ```

1. Configure **the KB** to allow common operations in it without needing to ask for permissions.<br/>
   See [settings.json file example for own KB].
1. Configure **user-level** settings to allow common operations **in the KB** from other projects without needing to ask
   for permissions.<br/>
   See [User-level settings.json patch example for own KB].
1. Add instructions in the **user-level** `CLAUDE.md` file.<br/>
   See [User-level CLAUDE.md patch example for own KB].
1. Ask Claude to initialize it (in a new session):

   > Hey! I have prepared your knowledge base repository for you. Please finish initializing it to your likings.

## Using tools

Refer to [Tools reference].

Claude Code comes with built-in tools (e.g. run shell commands, read and write files, search the web).<br/>
It can be extended to other tools by means of MCP servers and [skills][using skills].

MCP servers connect Claude Code to the data and give it tools to act on it, skills teach it what to do with them.

> [!caution]
> MCPs are **not** verified, nor otherwise checked for security issues.<br/>
> Be especially careful when using MCP servers that can fetch untrusted content, as they can fall victim of prompt
> injections.

Procedure:

1. Add the desired MCP servers.
1. From within Claude Code, run the `/mcp` command to configure them.

### Managing MCP servers

> [!tip]
> Prefer managing MCP servers via the `claude mcp` subcommands.

```sh
# Add MCP servers.
# Defaults to the 'local' scope if not specified.
claude mcp add --transport 'http' 'GitLab' 'https://gitlab.example.org/api/v4/mcp'
claude mcp add --transport 'http' 'linear' 'https://mcp.linear.app/mcp' --scope 'user'
claude mcp add 'aws-cost-explorer' --scope 'project' \
  --env 'AWS_REGION=eu-west-1' --env 'AWS_API_MCP_TELEMETRY=false' \
  -- \
  docker run --rm --interactive --volume "$HOME/.aws:/app/.aws" \
    --env 'AWS_REGION' --env 'AWS_API_MCP_TELEMETRY' \
    'public.ecr.aws/awslabs-mcp/awslabs/cost-explorer-mcp-server:latest'

# List installed MCP servers.
claude mcp list

# Show MCP servers' details
claude mcp get 'linear'

# Remove MCP servers.
claude mcp remove 'github'
```

Alternatively, directly edit `$HOME/.claude.json`.

<details style='padding: 0 0 1rem 1rem'>

```sh
# Add MCP servers.
jq '.mcpServers."grafana-aws" |= {
  "command": "docker",
  "args": [
    "run",
    "--rm",
    "--interactive",
    "--env", "GRAFANA_URL",
    "--env", "GRAFANA_SERVICE_ACCOUNT_TOKEN",
    "grafana/mcp-grafana:latest",
    "-t", "stdio"
  ],
  "env": {
    "GRAFANA_URL": "https://g-abcdef0123.grafana-workspace.eu-west-1.amazonaws.com",
    "GRAFANA_SERVICE_ACCOUNT_TOKEN": "glsa_abc…def"
  }
}' "$HOME/.claude.json" \
| sponge "$HOME/.claude.json"
```

</details>

> [!important]
> Values for environment variables **must be strings**.<br/>
> Giving other types will violate the schema Claude Code uses to validate the configuration file. The app will complain
> about it and **not** load the MCP server.

Configuration examples:

<details style='padding: 0 0 0 1rem'>
  <summary>AWS API</summary>

Refer to [AWS API MCP Server].

Enables interacting with AWS services and resources through AWS CLI commands.

> [!important]
> The container's `/app/.aws` folder must be **writable** (no `:ro` in the volume specification).<br/>
> The volume's path is **not** expanded in the shell. Use plain strings with **no** variables.

```json
{
  "mcpServers": {
    "aws-api-ro": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "--interactive",
        "--env", "AWS_API_MCP_TELEMETRY",
        "--env", "AWS_REGION",
        "--env", "READ_OPERATIONS_ONLY",
        "--volume", "/home/path/.aws:/app/.aws:rw",
        "public.ecr.aws/awslabs-mcp/awslabs/aws-api-mcp-server:latest"
      ],
      "env": {
        "AWS_API_MCP_TELEMETRY": "false",
        "AWS_REGION": "eu-west-1",
        "READ_OPERATIONS_ONLY": "true"
      }
    },
    "aws-api-rw": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "--interactive",
        "--env", "AWS_API_MCP_TELEMETRY=false",
        "--env", "AWS_API_MCP_PROFILE_NAME=operator",
        "--env", "AWS_REGION=eu-west-1",
        "--env", "REQUIRE_MUTATION_CONSENT=true",
        "--volume", "/home/path/.aws:/app/.aws:rw",
        "public.ecr.aws/awslabs-mcp/awslabs/aws-api-mcp-server:latest"
      ]
    }
  }
}
```

</details>

<details style='padding: 0 0 0 1rem'>
  <summary>AWS Cost Explorer</summary>

Refer to [AWS Cost Explorer MCP Server].

Enables analyzing AWS costs and usage data through the AWS Cost Explorer API.

> [!important]
> The container's `/app/.aws` folder must be **writable** (no `:ro` in the volume specification).<br/>
> The volume's path is **not** expanded in the shell. Use plain strings with **no** variables.

```json
{
  "mcpServers": {
    "aws-cost-explorer": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "--interactive",
        "--env", "AWS_API_MCP_TELEMETRY",
        "--env", "AWS_REGION",
        "--volume", "/home/path/.aws:/app/.aws:rw",
        "public.ecr.aws/awslabs-mcp/awslabs/cost-explorer-mcp-server:latest"
      ]
    }
  }
}
```

</details>

<details style='padding: 0 0 0 1rem'>
  <summary>GitLab</summary>

Enables interacting with GitLab instances through the GitLab API.

```json
{
  "mcpServers": {
    "gitlab": {
      "type": "http",
      "url": "https://gitlab.example.org/api/v4/mcp"
    }
  }
}
```

</details>

<details style='padding: 0 0 0 1rem'>
  <summary>Grafana</summary>

Refer to [Grafana MCP Server].

```json
{
  "mcpServers": {
    "grafana-aws": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "--interactive",
        "--env", "GRAFANA_URL",
        "--env", "GRAFANA_SERVICE_ACCOUNT_TOKEN",
        "grafana/mcp-grafana:latest",
        "-t", "stdio",
        "--disable-write",
        "--disable-admin"
      ],
      "env": {
        "GRAFANA_URL": "https://g-abcdef0123.grafana-workspace.eu-west-1.amazonaws.com",
        "GRAFANA_SERVICE_ACCOUNT_TOKEN": "glsa_abc…def"
      }
    },
    "grafana-local": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "--interactive",
        "--env", "GRAFANA_URL",
        "--env", "GRAFANA_USERNAME",
        "--env", "GRAFANA_PASSWORD",
        "--env", "GRAFANA_ORG_ID",
        "grafana/mcp-grafana:latest",
        "-t", "stdio"
      ],
      "env": {
        "GRAFANA_URL": "https://g-abcdef0123.grafana-workspace.eu-west-1.amazonaws.com",
        "GRAFANA_USERNAME": "some-user",
        "GRAFANA_PASSWORD": "some-password",
        "GRAFANA_ORG_ID": "1"
      }
    }
  }
}
```

</details>

<details style='padding: 0 0 1rem 1rem'>
  <summary>Linear</summary>

```json
{
  "mcpServers": {
    "linear": {
      "type": "http",
      "url": "https://mcp.linear.app/mcp"
    }
  }
}
```

</details>

### Limit tool execution

Use the `permissions` field in a settings file to always _allow_, require Claude Code to _ask_, or _deny_ the use of
specific tools.<br/>
`deny` takes precedence over `ask`, which in turn takes precedence over `allow`. The first matching rule **by category**
wins.

Spaces matter. `Bash(ls *)` matches `ls -la` or `ls` _followed by a space_ and then anything, but will **not** match
`ls` by itself, `lsof`, or other tools starting with it; `Bash(ls*)` matches **all** of them.<br/>
Use multiple patterns to achieve exact matches, e.g. `Bash(ls)` and `Bash(ls *)` for `ls` and its options but **not**
other tools which name matches partially.

Paths are considered in `gitignore` fashion: `/Users/alice/file` is _relative to the project's root_, **not** absolute.
Use `//` for the absolute root directory.<br/>
The tilde character at the start of paths is expanded automatically to the user's home directory in gitignore fashion.
This is confirmed as of 2026-04-14 for `Read`, `Edit`, `Write`, and `Bash` path patterns.

> [!important]
> MCP-related permission rule wildcards operate at the segment level (delimited by `__`), not character-by-character.
> Expressions like `mcp__*gitlab*__search` will **not** match any MCP server.
>
> The correct patterns for MCP-related permission are:
>
> - **Exact** matches for a **single** tool from the MCP server (e.g., `mcp__gitlab__search` for just the search tool).
> - **All tools** from an exact MCP server (e.g., `mcp__plugin_gitlab_gitlab__*`).
> - **Any single** tool from **any** MCP server (e.g., `mcp__*__search`).
> - **All tools** from **any** MCP server (e.g., `mcp__*`).

<details style='padding: 0 0 1rem 1rem'>

```json
{
  "permissions": {
    "deny": [
      "Read(~/.env)",
      "Read(~/.env.*)"
    ],
    "ask": [
      "Bash(git branch*)",
      "Bash(git commit*)",
      "mcp__aws_api__call_aws"
    ],
    "allow": [
      "Agent(Explore)",
      "Bash(git checkout*)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(git remote get-url*)",
      "Bash(git switch*)",
      "Edit(/**)",
      "Glob(/**)",
      "Grep(/**)",
      "Read(/**)",
      "TodoWrite",
      "Write(/**)"
    ]
  },
}
```

</details>

The official documentation talks explicitly about the `~/` expansion for `Read`, `Edit` and `Write` rules, but says
nothing about its use in `Bash()` rules. `Bash()` rules employ pure string matching.<br/>
The shell variable expansion results invisible to the permission layer. Claude Code inspects the command string
**before** handing it to the shell subprocess (where variables like `$HOME` would expand).

<details style='padding: 0 0 1rem 1rem'>

Commands using `$HOME/…` as double-quoted variable are **not** expanded until the shell subprocess runs.<br/>
The shell subprocess runs **after** permission checks. If a rule has `~/…`, it is either treated as a literal `~` or
expanded to the current user's home path, but it doesn't match the literal string `$HOME` in the command.

</details>

Rules in `settings.json` files should use absolute paths, e.g. `"Bash(git -C /home/some-user/path/to/whatever *)"`, or
Claude needs to know to use `~/` **unquoted** in KB commands instead of `$HOME/`.

Refine permissions using `PreToolUse` [hooks][using hooks].<br/>
`deny` and `ask` rules are **still** evaluated **after** a hook returns _allow_.

<details style='padding: 0 0 1rem 1rem'>

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__aws-cli__call_aws",
        "hooks": [
          {
            "type": "command",
            "command": "cmd=$(cat | jq -r 'if .cli_command | type == \"array\" then .cli_command[0] else .cli_command end'); [[ \"$cmd\" =~ ^aws[[:space:]]+[a-z-]+[[:space:]]+describe- ]] || { echo \"BLOCKED: only describe-* commands allowed\"; exit 2; }"
          }
        ]
      }
    ]
  }
}
```

</details>

Leverage [Sandboxing][documentation / sandboxing] to provide filesystem and network isolation for tool execution.<br/>
The sandboxed bash tool uses OS-level primitives to enforce defined boundaries upfront, and controls network access
through a proxy server running outside the sandbox.<br/>
Attempts to access resources outside the sandbox trigger immediate notifications.

> [!warning]
> Effective sandboxing requires **both** filesystem and network isolation.<br/>
> Without network isolation, compromised agents could exfiltrate sensitive files like SSH keys.<br/>
> Without filesystem isolation, compromised agents could backdoor system resources to gain network access.<br/>
> When configuring sandboxing, it is important to ensure that configured settings do not bypass these systems.

The sandboxed tool:

- Grants _default_ read and write access to the current working directory and its subdirectories.
- Grants _default_ read access to the entire computer, except specific denied directories.
- Blocks modifying files outside the current working directory without **explicit** permission.
- Allows defining custom allowed and denied paths through settings.
- Allows accessing only approved domains.
- Prompts the user when tools request access to new domains.
- Allows implementing custom rules on **outgoing** traffic.
- Applies restrictions to all scripts, programs, and subprocesses spawned by commands.

On macOS, Claude Code uses the built-in Seatbelt framework.<br/>
On Linux and WSL2, it requires installing [containers/bubblewrap] and `socat` before activation.<br/>
WSL1 is **not** supported.

Enable sandboxing interactively with the `/sandbox` command. <br/>
Sandboxing _can_ be configured to automatically allow execution of some or all commands within the sandbox **without**
requiring approval.<br/>
Commands that cannot be sandboxed fall back to the regular permission flow.

Customize sandbox behavior through the `settings.json` file.

When a command fails due to sandbox restrictions, Claude Code retries that command **outside** the sandbox using the
`dangerouslyDisableSandbox` parameter.<br/>
According to the docs, the retry should go through the **normal permissions flow** and require user approval.

> [!caution]
> In testing, the unsandboxed retry happened **automatically** with **no prompt at all**, even though Claude Code was
> set to ask for all actions.

<details style='padding: 0 0 1rem 1rem'>

Environment:

- Sandboxing was purposefully enabled manually in the session preceding the test one, both times.
- Claude Code was purposefully set to ask for **all** actions, both times.
- No automatic permission was configured for both Claude Code and in the repository, both times.

Project's `.claude/settings.json` file:

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": false
  }
}
```

Result:

```plaintext
• Sandbox restriction on commitlint. Let me retry outside the sandbox.
• Bash Commit staged changes (outside sandbox for commitlint)
  …
• Committed as `428547b`. All hooks passed.
```

</details>

Disable this behaviour by explicitly setting `allowUnsandboxedCommands` to `false` in the `sandbox` settings.<br/>
Claude Code completely ignores the `dangerouslyDisableSandbox` parameter. All commands should™ run sandboxed or be
explicitly listed in `excludedCommands`.

## Using skills

Refer to [Skills][documentation / skills] and [AI agents skills][ai agents / skills].<br/>
See also:

- [How to create custom Skills].
- [Improving skill-creator: Test, measure, and refine Agent Skills].
- [Anthropic's own source-available skills][anthropics/skills]
- [Prat011/awesome-llm-skills].
- This repository's [skills][claude-code/skills] and [skill examples][examples/claude-code/skills].

Claude Skills follow and extend the [Agent Skills] standard format.

Skills supersede and are meant to replace commands.<br/>
Existing `.claude/commands/` files will currently still work, but skills with the same name will take precedence.

Claude Code automatically discovers skills during initialization from:

- The user's `$HOME/.claude/skills/` directory, and sets them up as user-level skills.
- A project's `.claude/skills/` folder, and sets them up as project-level skills.
- A plugin's `<plugin>/skills/` folder, if such plugin is enabled.

Whatever the scope, skills must follow the `<scope-dir>/<skill-name>/SKILL.md` tree format, e.g.
`$HOME/.claude/skills/aws-action/SKILL.md` for a user-level skill.

User-level skills are available in all projects.<br/>
Project-level skills are limited to the current project.

Claude Code loads only the name and description of all skills during startup, then automatically loads and activates
only those skills that are relevant to the requests' context.<br/>
If the loaded skills reference other files, those are preemptively loaded together with the skill (_when_ it loads that
skill).

When working with files in subdirectories, Claude Code automatically discovers skills from nested `.claude/skills/`
directories.

Skills sharing the same name across different scopes replace one another with the most specific scope winning on the
broadest, and managed skills winning over everything:

```mermaid
flowchart LR
  m("Managed") --shadows--> s("Subdirectory") --shadows--> p("Project") --shadows--> u("User")
```

Plugin skills use a `plugin-name:skill-name` namespace, so they cannot conflict with other levels.<br/>
Files in `.claude/commands/` work the same way, but the skill will take precedence if a skill and a command share the
same name.

Each skill is a directory, with the `SKILL.md` file as the entrypoint:

```plaintext
some-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output, showing its expected format
└── scripts/           # Scripts that Claude can execute
    └── validate.sh
```

The `SKILL.md` files contain a description of the skill and the main, essential instructions that teach Claude how to
use it.<br/>
This file is required. All other files are optional and are considered _supporting_ files.<br/>
Optional files allow specifying further details and materials, like large reference docs, API specifications, or example
collections that do not need to be loaded into context every time the skill runs.<br/>
Reference optional files in `SKILL.md` to instruct Claude of what they contain and when to load them.

> [!tip]
> Prefer keeping `SKILL.md` under 500 lines.<br/>
> Move detailed reference material to supporting files.

Consider installing and using Claude's [_Skill Creator_ plugin][anthropics/skills/skill-creator] to create custom
skills.<br/>
It also allows for testing.

## Using plugins

Refer to [Plugins reference].

Reusable packages that bundle [Skills][using skills], agents, hooks, MCP servers, and LSP servers.<br/>
They extend Claude Code's functionality, and allow sharing extensions across projects and teams.

Can be installed at all different scopes.

Plugins bundle MCP servers via an `.mcp.json` file in the plugin's root, or inline in `plugin.json`.

> [!note]
> Claude Code's settings schema defines the top-level `pluginConfigs` key.<br/>
> It seems to be meant for _passing_ (not _overriding_) values to plugins. I was not yet able to make this work.

Plugins' MCP servers start automatically when the plugin is enabled.<br/>
These MCP servers appear as standard MCP tools in Claude's toolkit, just prefixed with `plugin:{plugin-name}` (e.g.
`plugin:gitlab:gitlab`). They can be configured independently.

<details style='padding: 0 0 1rem 1rem'>

```json
{
  "mcpServers": {
    "gitlab-custom": {
      "type": "http",
      "url": "https://gitlab.com/api/v4/mcp"
    },
    "plugin:gitlab:gitlab": {
      "type": "http",
      "url": "https://gitlab.example.org/api/v4/mcp"
    }
  }
}
```

```sh
$ claude mcp list
Checking MCP server health...

gitlab-custom: https://gitlab.com/api/v4/mcp (HTTP) - ! Needs authentication
plugin:gitlab:gitlab: https://gitlab.example.org/api/v4/mcp (HTTP) - ! Needs authentication
```

</details>

<details>
  <summary>Commands</summary>

```plaintext
# Browse, install, enable/disable, or manage plugins
/plugin
```

```sh
# Load local plugins.
claude --plugin-dir './path/to/plugin'

# Install plugin marketplaces.
claude plugin marketplace add 'owner/repo'      # github
claude plugins marketplace add 'path/to/plugin'  # local

# Install plugins.
# Marketplace defaults to 'claude-plugins-official'.
# Scope defaults to 'user'.
claude plugin install 'gitlab'
claude plugins i 'aws-cost-saver@aws-cost-saver-marketplace' --scope 'project'

# List installed plugins only.
claude plugins list

# List all plugins.
claude plugin list --available --json

# Enable plugins.
claude plugin enable 'skill-creator@claude-plugins-official'
claude plugin enable 'gitlab@claude-plugins-official'

# Disable plugins.
claude plugin disable 'gitlab@claude-plugins-official'

# Update plugins.
claude plugin update 'gitlab@claude-plugins-official'

# Uninstall plugins.
claude plugin uninstall 'gitlab@claude-plugins-official'
```

</details>

## Using hooks

Refer to [Automate workflows with hooks] and [Hooks reference].

Hooks force running user-defined shell commands automatically at specific points in Claude Code's lifecycle, e.g. when
it edits files, finishes tasks, or needs input.

They provide _**deterministic**_ control over Claude Code's behavior, ensuring certain actions **always** happen rather
than relying on the LLM to _choose_ to run them.<br/>

Use hooks to **enforce** project rules, automate repetitive tasks, and integrate Claude Code with existing tools.<br/>
Consider using [prompt-based hooks] or [agent-based hooks] for decisions that require **judgment**, rather than
deterministic rules.

When an event fires, all _matching_ hooks run **in parallel**.<br/>
Hooks defining a catch-all (`*`) matcher, an empty one (`""`), or no matcher at all, will match **all** events of their
specific type.

Identical hook commands are automatically **deduplicated**.<br/>
To make cheap checks short-circuit expensive ones, they would need to reside in a **single** hook that runs **both**
checks sequentially.

Create hooks by adding a `hooks` block to a settings file.

Filter tool events further by setting the `if` field on individual hook handlers.<br/>
The `if` field uses permission rule syntax to match against the tool name and arguments together, e.g. `"Bash(git *)"`
runs only for `git` commands and `"Edit(*.ts)"` runs only for TypeScript files.

<details style='padding: 0 0 1rem 1rem'>
  <summary>Examples</summary>

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "agent",
            "if": "Bash(git commit*)",
            "prompt": "Was Edit, Write, or NotebookEdit used in this conversation?\n  No  → \"LGTM\"\n  Yes → does the pending git commit mention \"Claude Code\" (in --author or Co-Authored-By)?\n    Yes → \"LGTM\"\n    No  → \"BLOCK: Commit has no Claude attribution. Reconsider your contribution:\n- Wrote most or all code: --author='Claude Code (<model>) on behalf of <user.name> <noreply@anthropic.com>' + 'Co-Authored-By: <user.name> <user.email>'\n- Minor fixes or review only: 'Co-Authored-By: Claude Code (<model>) <noreply@anthropic.com>'\nResolve user.name and user.email via git config. Never guess.\""
          },
          {
            "type": "command",
            "if": "Bash(git commit*)",
            "command": "current=$(git branch --show-current 2>/dev/null); default=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'); if [[ -z \"$default\" ]]; then default=$(git remote show origin 2>/dev/null | awk '/HEAD branch/{print $NF}'); fi; [[ -z \"$default\" ]] && default=\"master\"; if [[ \"$current\" == \"$default\" ]]; then echo \"BLOCKED: direct commits to '$default' are not allowed — create a feature branch first.\"; exit 2; fi; exit 0"
          },
          {
            "type": "agent",
            "prompt": "Review the proposed Bash command. Block it if it would: delete files outside the working directory, force-push, run pulumi up/destroy without the non-interactive task wrapper, or modify .env files. Allow everything else."
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "A new file is being created. Block this if the file is a .env file, a secret, or contains hardcoded credentials. Allow everything else. $ARGUMENTS",
            "timeout": 30
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "npx prettier --write \"$CLAUDE_FILE_PATH\" 2>/dev/null || true"
          },
          {
            "type": "http",
            "url": "http://localhost:8080/hooks/post-tool-use",
            "timeout": 10000,
            "headers": {
              "Authorization": "Bearer $MY_TOKEN"
            },
            "allowedEnvVars": ["MY_TOKEN"]
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":\"At the end of your response, consider whether this turn produced a durable technical insight (a gotcha, non-obvious fact, or synthesis). If yes, surface it and offer to document it in the project docs if project-specific, and/or in a knowledge base if reusable across projects.\"}}'"
          }
        ]
      }
    ]
  }
}
```

</details>

`PreToolUse` hooks fire once per **every** tool call.<br/>
Consider these for action-specific gates like commits or deployments, and scoping them further using the `if` field.

`TaskCompleted` hooks fire when a task created via the Task tool for background/parallel work finishes.<br/>
Exiting the REPL does **not** trigger `TaskCompleted` hooks. It will **only** fire when a subagent task completes.

Run commands at the end **of each response or session** by leveraging the `Stop` hook event.<br/>
It fires **on every turn**, **after** Claude **finished** writing its response, which forces Claude to regenerate it
from scratch and could be noisy depending on the action.<br/>
Use `Stop` hooks for broad post-work checks. It does catch brainstorming and research conversations.

> [!important]
> `Stop`'s `stdout` goes to debugging logs, not transcripts. Only `UserPromptSubmit` and `SessionStart` surface `stdout`
> as context for the agent.

Both prompt-based and agent-based hooks work **as gatekeepers** on `Stop` events, **not** as conversation
injectors.<br/>
They only return `{"ok": true/false, "reason": "..."}`, and only decide whether Claude should be allowed to stop.

`SessionEnd` has matchers for why a session ended (e.g., `clear`, `resume`, `logout`, `prompt_input_exit`,
`bypass_permissions_disabled`, others), but ends the REPL **before** the agent has the chance to act.

> [!note]
> There's currently no hook event that allows prompt or agent hooks just before exiting the REPL. `Ctrl+C` and `/exit`
> terminate the session **immediately**, without triggering any hook at all.<br/>
> `SessionEnd` prompt or agent hooks are not yet supported **outside** of the REPL. The closest alternative is using
> `Stop`, even though this generates noise and ends up eating lots of tokens.

`UserPromptSubmit` hooks fire **before** Claude starts thinking. It can inject `additionalContext` to shape the whole
response from the start.

Force a configuration reload and validate Claude Code accepted the hook by using the `/hooks` command.

> [!caution]
> Beware of prompts that can end up in loops. Consider asking Claude to detect and refine them.

Test the hook by asking Claude to do something that should trigger it.

> [!important]
> Scripts used in hooks must be executable.

Command hooks communicate only through `stdout`, `stderr`, and exit codes. They **cannot** trigger commands or tool
calls directly.<br/>
HTTP hooks only communicate through the response body.

### Prompt-based hooks

Prefer using these for **decisions** (and not _actions_) that require _judgment_ rather than deterministic rules.<br/>
Specifically, when the hook input data alone is enough to make a decision.

Prompt-based hooks make a **single** LLM call. Claude Code sends the prompt and the hook's input data to Claude to make
the defined decision.<br/>
They default to using Haiku. One can specify a different model by using the `model` field, but since it is just used to
decide whether to take action or not, it is usually not worth changing the model.

The model's **only** job is to return a yes/no decision as JSON. It has **no** access to tools.<br/>
If it returns `{"ok": true}`, the action proceeds. If it returns `false`, the action is blocked and the `reason` field
is fed back to Claude so it can adjust.

One can use `$ARGUMENTS` as a placeholder in the prompt to receive the hook's input data.

### Agent-based hooks

Prefer using these when verification requires inspecting files or running commands. Specifically, when in need to verify
something against the actual state of the codebase.

The harness spawns a sub-agent _per hook_ to execute the defined checks. Its goal should be only to _decide **whether**
to take action **or not**_, not to make changes themselves. Prefer configuring them to quickly return `block` with a
reason to the main agent instead.<br/>
Sub-agents default to using _fast_ models (currently Haiku). One _can_ specify a different model by using the `model`
field.

Prefer using clear, structured decision trees instead of narrative, and provide explicit conditions and required
outcomes.<br/>
Prose rules are slower to parse, and more prone to misinterpretation by fast models.

Scope the scan as precisely as possible. Ambiguous scope causes agents to look in the wrong place.<br/>
E.g., prefer writing something like "scan this conversation's tool call list" rather than "check tool use history".

Specify _exact_ output string if possible, e.g. `Output exactly 'LGTM' or 'BLOCK:' followed by one bullet per missing
item`.

Agents hooks are **fresh** invocations with limited context.<br/>
Avoid asking hooks to detect prior conversation state (e.g. "was this already suggested?"), as they'll miss prior state
and may cause false positives or loops. Keep conditions based on the current exchange, not history.

Spawned agents will inherit context from the main session through a transcript file, but they will access it **only** if
instructed to.

<details style='padding: 0 0 1rem 1rem'>
  <summary>Input to sub-agents during <code>Stop</code> hooks</summary>

| Field                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `last_assistant_message` | Full text of Claude's final response                                          |
| `stop_hook_active`       | true if Claude is already continuing from a prior stop hook (loop prevention) |
| `transcript_path`        | Path to the full conversation transcript (JSONL file)                         |
| `session_id`             | Current session ID                                                            |
| `cwd`                    | Working directory                                                             |
| `permission_mode`        | Current permission mode                                                       |

</details>

Agent-based hooks spawn a subagent that can read files, search code, and use other tools to verify conditions locally
before returning a decision.<br/>
They use an `ok`/`reason`-like response format as prompt hooks, but have a default timeout of 60 seconds.

<details style='padding: 0 0 1rem 1rem'>
  <summary>Example: keep <code>CONTRIBUTING.md</code> and <code>CLAUDE.md</code> updated</summary>

One wants to update the contents of `CONTRIBUTING.md` with findings from the current session.<br/>
The `Stop` hook is the closest to this goal (see note above).

Consider the following hook definition:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "If a documentation update was already suggested in this conversation, respond with only: LGTM. If the task was a routine code change that followed existing conventions, respond with only: LGTM. Otherwise, skim CONTRIBUTING.md and .claude/CLAUDE.md to check whether the task revealed a gotcha, pattern, convention, or decision not already covered. If so, state which file may need updating and ask the user if they would like to update it. Otherwise, respond with only: LGTM."
          }
        ]
      }
    ]
  }
}
```

Claude itself refined it multiple times.<br/>
The prompt needs to:

- _Clearly_ define the action the sub-agent needs to take.
- Avoid loops.<br/>
  E.g., make changes - revise - make more changes - revise again - and so on.
- Make the main agent _offer_ the user to make changes, not just go and make them.

After each task, the sub-agent inspects what was done and decides what the main agent should do.<br/>
In case the agent returned `{"decision": "block", "reason": "CONTRIBUTING.md should be updated. Ask the user …"}`,
the main agent is forced to continue and address the reason. Otherwise, it can stop as it would normally do.

One should see lines like the following during operations:

> • Good point from the hook. Let me also document this gotcha in CONTRIBUTING.md before applying the fix.<br/>
> • Good call. Let me add this to the troubleshooting section.

</details>

### HTTP hooks

Prefer using these to `POST` event data to an `HTTP` endpoint instead of running a shell command.<br/>
Specifically, when wanting a web server, cloud function, or external service to handle hook logic.

Claude Code sends the same `JSON` that a command hook would receive on stdin, and the endpoint must return results in
the HTTP response body using the same JSON format.

HTTP hooks support the `headers` field, and `allowedEnvVars` for passing environment variables.

Hook execution **continues** on non-`2xx` responses and connection failures.<br/>
An empty `2xx` body counts as success.

## Delegating work

[Agent teams] generally perform parallel tasks in less time, but consume more tokens (about N times, for N agents).<br/>
[Subagents] currently consistently produce better quality output than teams.

| /              | Subagents                              | Agent teams                                                                               |
| -------------- | -------------------------------------- | ----------------------------------------------------------------------------------------- |
| Model          | Hierarchical: spawn, work, report back | Peer-to-peer: independent sessions communicate via mailbox                                |
| Context        | Share parent's context window          | Own context window; load `CLAUDE.md` and MCP servers, but **not** the lead's conversation |
| Communication  | Only back to caller                    | Any teammate can message any other                                                        |
| File isolation | None (same working tree)               | [Git worktrees]: each agent edits independently, merges back                              |
| Coordination   | Caller manages                         | Shared task list that teammates can claim                                                 |
| Cost           | Moderate (still one session)           | Scales with team size                                                                     |

### Subagents

Refer to [Create custom subagents].

**Specialized** AI assistants with fixed roles, handling **specific** types of tasks.<br/>
Each runs in its own context window, with its own custom system prompt, specific access to tools, and independent
permissions.

When Claude encounters a task that matches a subagent's description, it delegates the task to that sub agent.<br/>
The sub agent works independently, and returns results once finished.

Most effective for sequential tasks, same-file edits, or tasks with many dependencies.<br/>
They only report results back to the main agent, and never talk to each other.

Claude Code includes several built-in subagents like _Explore_, _Plan_, and _general-purpose_.<br/>
One can create custom subagents to handle specific tasks.

Subagents are defined in Markdown files with YAML frontmatter.<br/>
Create them manually or use the `/agents` command.

<details style='padding: 0 0 1rem 1rem'>

```md
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
---

You are a code reviewer. When invoked, analyze the code and provide
specific, actionable feedback on quality, security, and best practices.
```

</details>

One can ask Claude to use subagents in sequence when dealing with multi-step workflows.<br/>
Each subagent completes its task and returns its results to Claude, which then passes relevant context to the next
subagent.

### Agent teams

> [!warning]
> Experimental feature as of 2026-04-18. Requires Claude Code v2.1.32+.

Refer to [Orchestrate teams of Claude Code sessions].

Multiple Claude Code instances can work together as a team.<br/>
One session acts as the team lead and coordinates work, assigns tasks, and synthesizes results.<br/>
Teammates work independently, have their **own** context window, and communicate **directly** with each other via a
mailbox system and a shared task list.

Each teammate operates in its own [git worktree][git worktrees] to allow concurrent edits to different files without
conflicts. Changes merge back when tasks complete.

Each teammate loads `CLAUDE.md` files and MCP servers, but do **not** inherit the lead's conversation history. They
start fresh.

One can interact with individual teammates directly, without going through the lead.

Most effective when teammates can operate independently.<br/>
They do exhibit coordination overhead, and use more tokens than a single session.

Progress is displayed in two modes:

- **In-process** (default), where all teammates run in the main terminal.<br/>
  `Shift+Down` cycles through them, and allows messaging them directly. Works everywhere.
- **Split-pane**, where each teammate gets its own pane.<br/>
  Requires [tmux], or iTerm2 with the `it2` CLI.<br/>
  Not supported in VS Code's integrated terminal or Windows Terminal.

Currently disabled by default.<br/>
Enable them by setting the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable to `1`, either in a shell
environment or through `settings.json`.

<details style='padding: 0 0 1rem 1rem'>

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

</details>

Tell Claude to create an agent team, describing the task and the desired team structure in natural language.<br/>
Claude creates the team with a shared task list, spawns teammates for each task, coordinates work based on the prompt,
and attempts to clean up the team when finished.

<details style='padding: 0 0 1rem 1rem'>

> [!note]
> The three roles are independent, so they can explore the problem without waiting on each other.

```plaintext
I'm designing a CLI tool that helps developers track TODO comments across their codebase.
Create an agent team to explore this from different angles: one teammate on UX, one on technical architecture, and one
playing devil's advocate.
```

```plaintext
Users report the app exits after one message instead of staying connected.
Spawn 5 agent teammates to investigate different hypotheses. Have them talk to each other to try to disprove each
other's theories, like a scientific debate.
Update the findings doc with whatever consensus emerges.
```

</details>

One can specify conditions and requirements in the prompt, like the number of teammates and whether they need to ask the
lead for approval before acting.

When requiring approvals:

- Teammates work in read-only mode until they need to act.
- Once finished planning, teammates send a plan approval request to the lead.
- The lead reviews the plan, and either approves it or rejects it with feedback.

  > [!important]
  > The lead makes approval decisions autonomously.<br/>
  > Give the lead criteria in the prompt to influence its judgment.

- If rejected, that teammate stays in plan mode, revises based on the feedback, and resubmits.
- Once approved, that teammate exits plan mode and begins implementation.

Gracefully end teammates' sessions by just asking the lead.<br/>
The lead sends them shutdown requests that the teammates can approve, exiting gracefully, or reject with an explanation.

<details style='padding: 0 0 1rem 1rem'>

```plaintext
Ask the researcher teammate to shut down
```

</details>

Clean up the team **after termination** by just asking the lead to clean up.<br/>
The lead will fail if any teammate is still running.

Known current limitations:

- Sessions cannot be resumed in in-process mode. `/resume` and `/rewind` do **not** restore teammates.
- Teammates sometimes fail to mark tasks as complete, blocking dependent work.
- Uses only **one** team per session. A teammate **cannot** spawn its own nested team.
- Teammates finish their current request before stopping.

### MCP servers in sub-agents

Refer to [Allow MCP tools to be available only to subagent] and [Enable specific MCP servers for sub-agents].

Sub-agents inherit **all** configured [MCP] servers by default, including their (often token-expensive) tool
definitions in the context window.<br/>
This both broadens the attack surface and consumes context window space in _every_ sub-agent, regardless of whether
the sub-agents use those servers.

When MCP servers run as containers using stdio transport, **each** sub-agent spawns its **own** container instance,
multiplying resource usage. Mitigate this by:

- Defining MCP servers **inline** in [sub-agent configurations][create custom subagents], instead of session-wide,
  to limit their lifespan and context to the sub-agent.
- Running containerized servers **independently**, and configuring them to use network transport (streamable HTTP or
  SSE). Multiple sub-agents may then connect to a single container running outside of their context.<br/>
  Servers configured session-wide, though, will still make every sub-agent load their tool definitions. Combine this
  with the inline definition method to achieve the complete effect.

<details style='padding: 0 0 1rem 0'>
  <summary>Inline MCP server definition example</summary>

Define containerized MCP servers in a sub-agent's frontmatter to scope them exclusively to that sub-agent:

```yaml
---
name: aws-researcher
description: Investigates AWS resources and costs
mcpServers:
  - aws-api:             # Inline stdio definition: single container, scoped to this sub-agent only.
      env:
        AWS_REGION: eu-west-1
      command: docker
      args:
        - run
        - --rm
        - --interactive
        - --env
        - AWS_REGION
        - --volume
        - /home/path/.aws:/app/.aws:rw
        - public.ecr.aws/awslabs-mcp/awslabs/aws-api-mcp-server:latest
  - aws-cost-explorer:   # Alternative: point to a shared container running on a network transport.
      type: http
      url: http://localhost:8000/mcp
---

Investigate AWS resources and costs using the available MCP tools.
```

The sub-agent gets the tools; the parent agent does not.

</details>

## Scheduling tasks

Refer to [Run prompts on a schedule] and [Schedule tasks on the web].

Schedule **one-shot** reminders and actions by describing the goal in natural language.<br/>
Claude pins the fire time to a specific minute and hour using a cron expression, schedules it, and confirms when it will
fire. The task will then delete itself after running.<br/>
E.g.:

- "Remind me at 3pm to push the release branch".
- "In 45 minutes, check whether the integration tests passed"

Schedule **recurring** work:

- In Anthropic's cloud service.
- In the desktop app.
- Using the `/loop` bundled skill in Claude Code.

  It sets up a cron job that fires in the background. If no interval is given, it defaults to 10 minutes.<br/>
  This skill **only runs while the current session stays open**.

- By just asking Claude in natural language to do it, e.g.:

  > Send "ping" to Haiku using `claude -p` every working day at 7 AM local time, or as soon as I wake up my laptop after
  > that time. Discard its answer.

  Claude will:

  1. Create a script for the action.
  1. Use the `CronCreate` tool to set up a system-level cron job that is **not** tied to Claude Code being open.

  If the local machine could be sleeping or shut down, prefer explicitly asking Claude to work around it.<br/>
  On macOS, ask to use `launchd` with `StartCalendarInterval` instead to fire the job as soon as the machine next wakes
  up. On Linux, ask to use a `systemd` timer or `anacron`.

Use cloud tasks for jobs that should run reliably **without** a local session.<br/>
Use Desktop tasks when in need to access local files and tools.<br/>
Use `/loop` for quick polling during an active session.<br/>
Describe the goal in natural language otherwise.

## Tools of interest

| Tool         | Summary                                                                          |
| ------------ | -------------------------------------------------------------------------------- |
| [rtk-ai/rtk] | Summarize CLI commands output. Avoids context pollution and reduces token usage. |

## Best practices

Document projects upfront (e.g. using [ADRs][adr], and [CONTRIBUTING.md] and README.md files).<br/>
Possibly consider including instructions specific to AI agents in those files, instead of including them only in
`CLAUDE.md`.

Be explicit about constraints and non-negotiables. **Clearly** state in `CLAUDE.md` files what Claude should **never**
do, e.g. delete specific files, modify configurations, break tests, etc.<br/>
Provide **explicit**, **clear** examples of what it need to do and how. Set expectations about when to ask for help.

Keep the `CLAUDE.md` files as small as possible.<br/>
If possible, prefer splitting it up per subfolder, with each only containing instructions related to the their own
directory. Subfolder files are **only** loaded if Claude Code actively works in those directories.

Have Claude read and understand the project layout, documentation, key files, and architecture **before** allowing it to
make changes. Reference those files in `CLAUDE.md` to make sure it loads them when needed.

Consider _delegating ownership_ of tools and documentation to Claude early in a project, making it responsible for
maintaining all the files it **uses** (not just those it creates).<br/>
**Periodically** ask it to check and update them. This might be an instruction in `CLAUDE.md` or `CONTRIBUTING.md`.

**Avoid** using Claude without human oversight for tasks that require deep domain knowledge or judgment calls, like
architectural decisions and security reviews. Prefer giving it easy, repeatable tasks like exploring the code,
refactoring, generating tests or boilerplate, and documentation.

Abuse version control checkpoints. Commit frequently to keep safe fallback points and isolate what Claude changed,
should something go wrong.<br/>
Review and test changes **incrementally**, especially when involving critical files.

Run `/insights` to get feedback, tips and suggestions on how one could improve their Claude Code usage.<br/>
Claude bases those tips on one's history and session analysis.

Prefer CLI utilities over MCP servers. They're lighter, faster, independent, work offline (unless they require
connecting to a server), and do not hog the session's context just by existing.<br/>
Prefer MCP servers over CLI tools when requiring persistent states across sessions or bidirectional communication, or
when using different operating systems and requiring standardized interfaces.

Optimize model usage to avoid burning through credits:

- Use **different** sessions for unrelated tasks instead of a single, continuous session.<br/>
  Existing context is always sent in its entirety for every message.
- Start by _planning_ the approach to one's goals, refine it, break large tasks into smaller, reviewable ones, and
  **then** act.
- Start by using **Sonnet**, switch to Opus in case Sonnet proves not capable enough, and prefer Sonnet or even Haiku
  for actions.<br/>
  Leverage the `opusplan` mode to use Opus during the design or planning phase (`/plan`), then automatically switch to
  Sonnet for implementation.
- Track session usage to identify what tasks are expensive to delegate, and review and adjust one's patterns.

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
Claude Code version: `v2.1.41`.

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
- [How Claude Code works]
- [AI agents]
- Alternatives: [Gemini CLI], [OpenCode], [Pi]
- [Claude Code router]
- [Settings][documentation / settings]
- [Prat011/awesome-llm-skills]
- [Claude Skills vs. MCP: A Technical Comparison for AI Workflows]
- [Improving skill-creator: Test, measure, and refine Agent Skills]
- The blog posts by Sergei Rastrigin about Claude Code's inner workings:
  1. [What Claude Code Actually Sends to the Cloud][claude analysis / what claude code actually sends to the cloud]
  1. [The System Prompt][claude analysis / the system prompt]
- [The Claude Skills I Actually Use for DevOps]
- [Output styles]
- [Claude Code Unpacked]

### Sources

- [Documentation]
- [pffigueiredo/claude-code-sheet.md]
- [Mastering Claude Code in 30 minutes] by Boris Cherny, Anthropic
- [Writing a good CLAUDE.md]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Agent teams]: #agent-teams
[Agent-based hooks]: #agent-based-hooks
[Configuration]: #configuration
[Prompt-based hooks]: #prompt-based-hooks
[Subagents]: #subagents
[Using hooks]: #using-hooks
[Using skills]: #using-skills

<!-- Knowledge base -->
[ADR]: ../../adr.md
[AI agents / Context and memory]: ../agents.md#context-and-memory
[AI agents / Skills]: ../agents.md#skills
[AI agents]: ../agents.md
[Claude Code router]: claude%20code%20router.md
[Claude]: README.md
[CONTRIBUTING.md]: ../../contributingmd.md
[Gemini CLI]: ../gemini/cli.md
[git worktrees]: ../../git.md#worktrees
[MCP]: ../mcp.md
[Ollama]: ../ollama.md
[OpenCode]: ../opencode.md
[Pi]: ../pi.md
[tmux]: ../../tmux.md

<!-- Files -->
[.mcp.json file example]: ../../../examples/claude-code/dotmcp.json
[~/.claude/credentials.json file example]: ../../../examples/claude-code/credentials.json
[claude-code/skills]: ../../../claude-code/skills
[examples/claude-code/skills]: ../../../examples/claude-code/skills
[settings.json file example for own KB]: ../../../examples/claude-code/own-kb/kb.settings.json
[settings.json file example]: ../../../examples/claude-code/settings.json
[User-level CLAUDE.md patch example for own KB]: ../../../examples/claude-code/own-kb/user.CLAUDE.md.patch
[User-level settings.json patch example for own KB]: ../../../examples/claude-code/own-kb/user.settings.patch.json

<!-- Upstream -->
[anthropics/skills]: https://github.com/anthropics/skills
[anthropics/skills/skill-creator]: https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md
[Automate workflows with hooks]: https://code.claude.com/docs/en/hooks-guide
[Blog]: https://claude.com/blog
[Built-in commands reference]: https://code.claude.com/docs/en/commands
[CLI reference]: https://code.claude.com/docs/en/cli-reference
[Codebase]: https://github.com/anthropics/claude-code
[Create custom subagents]: https://code.claude.com/docs/en/sub-agents
[Documentation / Sandboxing]: https://code.claude.com/docs/en/sandboxing
[Documentation / Settings]: https://code.claude.com/docs/en/settings
[Documentation / Skills]: https://code.claude.com/docs/en/skills
[Documentation]: https://code.claude.com/docs/en/overview
[Environment variables reference]: https://code.claude.com/docs/en/env-vars
[Hooks reference]: https://code.claude.com/docs/en/hooks
[How Claude Code works]: https://code.claude.com/docs/en/how-claude-code-works
[How to create custom Skills]: https://support.claude.com/en/articles/12512198-how-to-create-custom-skills
[Improving skill-creator: Test, measure, and refine Agent Skills]: https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills
[InstructionsLoaded hook]: https://code.claude.com/docs/en/hooks#instructionsloaded
[Manage Claude's memory]: https://code.claude.com/docs/en/memory
[Mastering Claude Code in 30 minutes]: https://www.youtube.com/watch?v=6eBSHbLKuN0
[Orchestrate teams of Claude Code sessions]: https://code.claude.com/docs/en/agent-teams
[Output styles]: https://code.claude.com/docs/en/output-styles
[Plugins reference]: https://code.claude.com/docs/en/plugins-reference
[Run prompts on a schedule]: https://code.claude.com/docs/en/scheduled-tasks
[Schedule tasks on the web]: https://code.claude.com/docs/en/web-scheduled-tasks
[Subagent memory configuration]: https://code.claude.com/docs/en/sub-agents#enable-persistent-memory
[Tools reference]: https://code.claude.com/docs/en/tools-reference
[Website]: https://claude.com/product/overview

<!-- Others -->
[Agent Skills]: https://agentskills.io/
[Allow MCP tools to be available only to subagent]: https://github.com/anthropics/claude-code/issues/6915
[AWS API MCP Server]: https://github.com/awslabs/mcp/tree/main/src/aws-api-mcp-server
[AWS Cost Explorer MCP Server]: https://github.com/awslabs/mcp/tree/main/src/cost-explorer-mcp-server
[Claude analysis / The System Prompt]: https://rastrigin.systems/blog/claude-code-part-2-system-prompt/
[Claude analysis / What Claude Code Actually Sends to the Cloud]: https://rastrigin.systems/blog/claude-code-part-1-requests/
[Claude Code Unpacked]: https://ccunpacked.dev/
[Claude Skills vs. MCP: A Technical Comparison for AI Workflows]: https://intuitionlabs.ai/articles/claude-skills-vs-mcp
[containers/bubblewrap]: https://github.com/containers/bubblewrap
[Enable specific MCP servers for sub-agents]: https://github.com/anthropics/claude-code/issues/16177
[Grafana MCP Server]: https://github.com/grafana/mcp-grafana
[karpathy/llm-wiki.md]: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
[pffigueiredo/claude-code-sheet.md]: https://gist.github.com/pffigueiredo/252bac8c731f7e8a2fc268c8a965a963
[Prat011/awesome-llm-skills]: https://github.com/Prat011/awesome-llm-skills
[rtk-ai/rtk]: https://github.com/rtk-ai/rtk
[Settings' schema]: https://www.schemastore.org/claude-code-settings.json
[The Claude Skills I Actually Use for DevOps]: https://www.pulumi.com/blog/top-8-claude-skills-devops-2026/
[thedotmack/claude-mem]: https://github.com/thedotmack/claude-mem
[Writing a good CLAUDE.md]: https://www.humanlayer.dev/blog/writing-a-good-claude-md
