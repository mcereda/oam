# Large language model

_Language models_ are computational model that can predict sequences in natural language.<br/>
Useful for speech recognition, machine translation, natural language generation, optical character recognition, route
optimization, handwriting recognition, grammar induction, information retrieval, and other tasks.

_Large_ language models are predominantly based on transformers trained on large datasets, frequently including texts
scraped from the Internet.<br/>
They have superseded recurrent neural network-based models.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Reasoning](#reasoning)
1. [Concerns](#concerns)
1. [Run LLMs Locally](#run-llms-locally)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

| FIXME     | Creator    |
| --------- | ---------- |
| [ChatGPT] | OpenAI     |
| [Claude]  | Anthropic  |
| [Copilot] | Microsoft  |
| [Duck AI] | DuckDuckGo |
| [Gemini]  | Google     |
| [Grok]    | X          |
| [Llama]   | Meta       |
| [Mistral] | Mistral AI |

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Reasoning

Standard is just autocompletion. Models just try to infer or recall what the most probable next word would be.

Chain of Thought tells models to _show their work_. It _feels_ like the model is calculating or thinking.<br/>
What it really does is just increasing the chances that the answer is correct by breaking the user's questions in
smaller, more manageable steps, and solving on each of them before giving back the final answer.<br/>
The result is more accurate, but it costs more tokens and requires a bigger context window.

At some point we gave models the ability to execute commands. This way the model can use (or even create) them to get
or check the answer, instead of just infer or recall it.

The ReAct loop (reason+act) came next, where the model loops on the things above. Breaks the request in smaller steps,
acts on them using functions if necessary, checks the results, updates the chain of thoughts, repeat until the request
is satisfied.

Next step is [agentic AI][agent].

## Concerns

- Lots of people currently thinks of LLMs as _real intelligence_, when it is not.
- People currently gives too much credibility to LLM answers, and trust them more than they trust their teachers,
  accountants, lawyers or even doctors.
- AI companies could bias their models to say specific things, subtly promote ideologies, influence elections, or even
  rewrite history in the mind of those who trust the LLMs.
- Models can be vulnerable to specific attacks (e.g. prompt injection) that would change the LLM's behaviour, bias it,
  or hide malware in their tools.
- People is using LLMs mindlessly too much, mostly due to the convenience they offer but also because they don't understand
  what those are or how they work. This is causing lack of critical thinking and overreliance.
- Model training and execution requires resources that are normally not available to the common person. This encourages
  people to depend from, and hence give power to, AI companies.

## Run LLMs Locally

Refer:

- [Local LLM Hosting: Complete 2026 Guide - Ollama, vLLM, LocalAI, Jan, LM Studio & More].
- [Run LLMs Locally: 6 Simple Methods].

[Ollama]| [Jan] |[LMStudio] | [Docker model runner] | [llama.cpp] | [vLLM] | [Llamafile]

## Further readings

### Sources

- [Run LLMs Locally: 6 Simple Methods]
- [OpenClaw: Who are you?]
- [Local LLM Hosting: Complete 2026 Guide - Ollama, vLLM, LocalAI, Jan, LM Studio & More]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Agent]: agent.md
[Claude]: claude/README.md
[Docker model runner]: ../docker.md#running-llms-locally
[Gemini]: gemini/README.md
[llama.cpp]: llama.cpp.md
[LMStudio]: lmstudio.md
[Ollama]: ollama.md
[vLLM]: vllm.md

<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[ChatGPT]: https://chatgpt.com/
[Copilot]: https://copilot.microsoft.com/
[Duck AI]: https://duck.ai/
[Grok]: https://grok.com/
[Jan]: https://www.jan.ai/
[Llama]: https://www.llama.com/
[Llamafile]: https://github.com/mozilla-ai/llamafile
[Local LLM Hosting: Complete 2026 Guide - Ollama, vLLM, LocalAI, Jan, LM Studio & More]: https://www.glukhov.org/post/2025/11/hosting-llms-ollama-localai-jan-lmstudio-vllm-comparison/
[Mistral]: https://mistral.ai/
[OpenClaw: Who are you?]: https://www.youtube.com/watch?v=hoeEclqW8Gs
[Run LLMs Locally: 6 Simple Methods]: https://www.datacamp.com/tutorial/run-llms-locally-tutorial
