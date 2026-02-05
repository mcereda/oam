# Use a local LLM for coding assistance in VSCode

1. [Setup](#setup)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Setup

1. Install Ollama and download the models you mean to use.<br/>
   Refer [Ollama].

   <details style='padding: 0 0 1rem 1rem'>

   ```sh
   brew install 'ollama'
   ollama pull 'llama3.1:8b'
   ollama pull 'qwen2.5-coder:7b'
   ollama pull 'nomic-embed-text:latest'
   ```

   </details>

1. Install the [Continue VSCode extension].
1. Configure the extension to use local LLMs only.

   <details style='padding: 0 0 1rem 1rem'>

   1. Open the extension's sidebar.
   1. In the top-right, select Local Config from the dropdown menu.
   1. Eventually, tweak the configuration file.

   </details>

## Further readings

- [Large Language Model] (LLM)
- [Ollama]
- [Continue VSCode extension]

### Sources

- [How to use a local LLM as a free coding copilot in VS Code]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Large Language Model]: large%20language%20model.md
[Ollama]: ollama.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[Continue VSCode extension]: https://marketplace.visualstudio.com/items?itemName=Continue.continue
[How to use a local LLM as a free coding copilot in VS Code]: https://medium.com/@smfraser/how-to-use-a-local-llm-as-a-free-coding-copilot-in-vs-code-6dffc053369d
