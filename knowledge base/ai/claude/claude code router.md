# Claude Code router

> TODO

Allows using [Claude Code] **without** an Anthropic account.<br/>
Connects it to most other LLMs, including local ones.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

Both the `ccr` CLI and the server use the `~/.claude-code-router/config.json` configuration file.

```sh
# Install.
brew install 'claude-code-router'
npm install -g '@musistudio/claude-code-router'

# Open the Web UI for visual configuration.
ccr ui
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Start the service.
ccr start

# View the service's status.
ccr status

# Restart the service.
ccr restart

# Stop the service.
ccr stop

# Select models.
# ccr model set <provider>,<model>
ccr model
ccr model set 'deepseek,deepseek-chat'

# List configured models.
ccr model list

# Add models.
# ccr model add <provider>,<model>
ccr model add 'groq,llama-3.3-70b-versatile'

# Remove models.
# ccr model remove <provider>,<model>
ccr model remove 'groq,llama-3.3-70b-versatile'

# Start Cloud Code.
# Do this AFTER configuring CCR.
ccr code
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
- [Claude Code]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Claude Code]: claude%20code.md

<!-- Files -->
<!-- Upstream -->
[Blog]: https://musistudio.github.io/claude-code-router/blog
[Codebase]: https://github.com/musistudio/claude-code-router
[Documentation]: https://musistudio.github.io/claude-code-router/docs/category/cli
[Website]: https://musistudio.github.io/claude-code-router/

<!-- Others -->
