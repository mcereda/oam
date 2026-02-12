# Gemini CLI

> TODO

Open-source AI agent that allows to use Google Gemini from a terminal.<br/>
Can read and edit files, execute shell commands, and search the web.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install.
npm install -g '@google/gemini-cli'

# Run without installation.
docker run --rm -it 'us-docker.pkg.dev/gemini-code-dev/gemini-cli/sandbox:0.1.1'
npx '@google/gemini-cli'

# Configure API keys.
export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Start.
gemini

# Run inside a container.
# If installed locally.
gemini --sandbox -y -p "your prompt here"

# Headless mode.
gemini -p "What is fine tuning?"
echo "What is fine tuning?" | gemini
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
- [Gemini]
- [AI agent]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[AI agent]: ../agent.md
[Gemini]: README.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/google-gemini/gemini-cli
[Documentation]: https://geminicli.com/docs/
[Website]: https://geminicli.com/

<!-- Others -->
