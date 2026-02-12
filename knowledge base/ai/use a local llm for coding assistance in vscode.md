# Use a local LLM for coding assistance in VSCode

1. [Setup](#setup)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Setup

<details>
  <summary>Ollama + Continue (preferred)</summary>

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
   1. Add the model to the configuration file.<br/>
      Make sure to use the `ollama` provider.

      ```yml
      name: Local Config
      version: 1.0.0
      schema: v1
      models:
        - name: Qwen 2.5 Coder 7b Ollama
          provider: ollama
          model: qwen2.5-coder:7b
          roles:
            - autocomplete
            - chat
            - edit
            - apply
          defaultCompletionOptions:
            contextLength: 16384  # number of tokens, defaulted to 4096 for this model
      ```

   1. If needed, tweak the configuration file.

   </details>

</details>

<details>
  <summary>Docker Desktop + Continue</summary>

1. Install Docker Desktop
1. Enable Model Runner with TCP support and download the models you mean to use.<br/>
   Refer [Running LLMs locally][docker  running llms locally].

   <details style='padding: 0 0 1rem 1rem'>

   ```sh
   docker desktop enable model-runner --tcp='12434'
   docker model status
   docker model pull 'ai/qwen2.5'
   ```

   </details>

1. Install the [Continue VSCode extension].
1. Configure the extension to use local LLMs only.

   <details style='padding: 0 0 1rem 1rem'>

   1. Open the extension's sidebar.
   1. In the top-right, select Local Config from the dropdown menu.
   1. Add the model to the configuration file.<br/>
      Make sure to use the `openai` provider and configure the `apiBase` attribute.

      ```yml
      name: Local Config
      version: 1.0.0
      schema: v1
      models:
        - name: Qwen 2.5 Docker
          provider: openai
          model: ai/qwen2.5
          apiBase: http://localhost:12434/engines/v1
          apiKey: not-needed
          roles:
            - apply
            - autocomplete
            - chat
            - edit
      ```

   1. If needed, tweak the configuration file.

   </details>

</details>

## Further readings

- [Large Language Model] (LLM)
- [Ollama]
- [Docker]
- [Continue VSCode extension]
- [Docker Model Runner vs Ollama: Which to Choose?]

### Sources

- [How to use a local LLM as a free coding copilot in VS Code]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Docker]: ../docker.md
[Docker  Running LLMs locally]: ../docker.md#running-llms-locally
[Large Language Model]: large%20language%20model.md
[Ollama]: ollama.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[Continue VSCode extension]: https://marketplace.visualstudio.com/items?itemName=Continue.continue
[Docker Model Runner vs Ollama: Which to Choose?]: https://www.glukhov.org/post/2025/10/docker-model-runner-vs-ollama-comparison/
[How to use a local LLM as a free coding copilot in VS Code]: https://medium.com/@smfraser/how-to-use-a-local-llm-as-a-free-coding-copilot-in-vs-code-6dffc053369d
