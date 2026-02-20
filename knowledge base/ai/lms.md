# Language models

_Language models_ are **statistical** models designed to understand, generate, and predict sequences of words in natural
language.<br/>
They analyze the structure and use of language to perform tasks such as machine translation, text generation, and
sentiment analysis.

1. [TL;DR](#tldr)
1. [Large Language Models](#large-language-models)
1. [Inference](#inference)
   1. [Speculative decoding](#speculative-decoding)
1. [Reasoning](#reasoning)
1. [Prompting](#prompting)
1. [Function calling](#function-calling)
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

LLms are good at understanding human prompts in natural language.

Many models now come pre-trained, and one can use the same model for classification, summarisation, answering questions,
data extraction, generation, reasoning, planning, translation, coding, and more.<br/>
They can be also be further trained on additional information specific to an industry niche or a particular business.

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

## Large Language Models

_Large_ language models are language models trained on massive datasets, frequently including texts scraped from the
Internet.

They are currently predominantly based on _transformers_, which have superseded recurrent neural networks as the most
effective technology.

LLMs are especially proficient in speech recognition, machine translation, natural language generation, optical
character recognition, route optimization, handwriting recognition, grammar induction, information retrieval, and other
tasks.

## Inference

### Speculative decoding

Refer:

- [Fast Inference from Transformers via Speculative Decoding].
- [Accelerating Large Language Model Decoding with Speculative Sampling].
- [An Introduction to Speculative Decoding for Reducing Latency in AI Inference].
- [Looking back at speculative decoding].

Makes inference faster and more responsive, significantly reducing latency while preserving output quality by
predicting and verifying multiple tokens simultaneously.

Pairs a target LLM with a less resource-intensive _draft_ model.<br/>
The smaller model quickly proposes several next tokens to the target model, offloading it of part of the standard
autoregressive decoding it would normally do and hence reducing the number of sequential steps.<br/>
The target model verifies the proposed tokens in a single forward pass instead of one at a time, accepts the longest
prefix that matches its own predictions, and continues from there.

Generating multiple tokens at once cuts latency and boosts throughput without impacting accuracy.

Use cases:

- Speeding up input-grounded tasks like translation, summarization, and transcription.
- Performing greedy decoding by always selecting the most likely token.
- Low-temperature sampling when outputs need to be focused and predictable.
- The target model barely fits in the GPU's memory.

Cons:

- Increases memory overhead due to both models needing to be loaded at the same time.
- Less effective for high-temperature sampling (e.g. creative writing).
- Benefits drop if the draft model is poorly matched to the target model.
- Gains are minimal for very small target models that already fit easily in memory.

Effectiveness depends on selecting the right draft model.<br/>
A poor choice will grant minimal speedup, or even slow things down.

The draft model must have:

- At least 10× **_fewer_** parameters than the target model.<br/>
  Large draft models will generate tokens more slowly, which defeats the purpose.
- The same tokenizer as the target model.<br/>
  This is non-negotiable, since the two models must follow the same internal processes to be compatible.
- Similar training data, to maximize the target model's acceptance rate.
- Same architecture family when possible

Usually, a distilled or simplified version of the target model works best.<br/>
For domain-specific applications, consider fine-tuning a small model to mimic the target model's behavior.

## Reasoning

Standard models' behaviour is just autocompletion. Models just try to infer or recall what the most probable next word
would be.

_Chain of Thought_ techniques tell models to _show their work_.
It _feels_ like a model is calculating or thinking, but what it is really just increasing the chances that the answer
is correct by breaking questions in smaller, more manageable steps, and solving on each of them before giving back the
final answer.<br/>
The result is more accurate, but it costs more tokens and requires a bigger context window.

The _ReAct loop_ (Reason + Act) paradigm forces models to loop over chain-of-thoughts.<br/>
A model breaks the request in smaller steps, plans the next action, acts on it using [functions][function calling]
should it decide it needs to, checks the results, updates the chain of thoughts, and repeats this Think-Act-Observe loop
to iteratively improve upon responses.

The _ReWOO_ (Reasoning WithOut Observation) method eliminates the dependence on tool outputs for action planning.<br/>
Models plan upfront, and avoid redundant usage of tools by anticipating which tools to use upon receiving the initial
prompt from the user.<br/>
Users can confirm the plan **before** the model executes it.

[AI agents][agent] use these methods to act autonomously.

## Prompting

_Good_ prompting is about designing predictable interactions with a model.<br/>
In the context of LLM agent development, it is no different from interface design.

## Function calling

Refer [Function calling in LLMs].

A.K.A _tool-calling_.<br/>
Allows models to reliably connect and interact with external tools or APIs.

One provides the LLM with a set of tools, and the model _decides_ during interaction which tool it wants to invoke for
a specific prompt and/or to complete a given task.<br/>
Models supporting function calling can use (or even create) tools to get or check an answer, instead of just infer or
recall it.

Function calling grants models real-time data access and information retrieval.<br/>
This eliminates the fundamental problem of them giving responses based on stale training data, and reduces
hallucination episodes that come from them not accepting they don't know something.

Using tools increases the overall token count and hence costs, also reducing available context and adding latency.<br/>
Deciding which tool to call, using that tool, and then using the results to generate a response is more intensive than
just inferring the next token.

> [!caution]
> Allowing a LLM to call functions can have real-world consequences.<br/>
> This includes financial loss, data corruption or exfiltration, and security breaches.

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
- Models tend to **not** accept gracefully that they don't know something, and hallucinate as a result.<br/>
  More recent techniques are making models more efficient, but they just delay this problem.
- Models can learn and exhibit deceptive behavior.<br/>
  Standard techniques could fail to remove it, and instead empower it while creating a false impression of safety.<br/>
  See [Sleeper Agents: Training Deceptive LLMs that Persist Through Safety Training].

## Run LLMs Locally

Refer:

- [Local LLM Hosting: Complete 2026 Guide - Ollama, vLLM, LocalAI, Jan, LM Studio & More].
- [Run LLMs Locally: 6 Simple Methods].

[Ollama]| [Jan] |[LMStudio] | [Docker model runner] | [llama.cpp] | [vLLM] | [Llamafile]

## Further readings

- [SEQUOIA: Serving exact Llama2-70B on an RTX4090 with half-second per token latency]
- [Optimizing LLMs for Performance and Accuracy with Post-Training Quantization]
- [Sleeper Agents: Training Deceptive LLMs that Persist Through Safety Training]

### Sources

- [Run LLMs Locally: 6 Simple Methods]
- [OpenClaw: Who are you?]
- [Local LLM Hosting: Complete 2026 Guide - Ollama, vLLM, LocalAI, Jan, LM Studio & More]
- [LLM skills every AI engineer must know]
- [Function calling in LLMs]
- [What is chain of thought (CoT) prompting?]
- [What are Language Models in NLP?]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Function calling]: #function-calling

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
[Accelerating Large Language Model Decoding with Speculative Sampling]: https://arxiv.org/abs/2302.01318
[An Introduction to Speculative Decoding for Reducing Latency in AI Inference]: https://developer.nvidia.com/blog/an-introduction-to-speculative-decoding-for-reducing-latency-in-ai-inference/
[ChatGPT]: https://chatgpt.com/
[Copilot]: https://copilot.microsoft.com/
[Duck AI]: https://duck.ai/
[Fast Inference from Transformers via Speculative Decoding]: https://arxiv.org/abs/2211.17192
[Function calling in LLMs]: https://www.geeksforgeeks.org/artificial-intelligence/function-calling-in-llms/
[Grok]: https://grok.com/
[Jan]: https://www.jan.ai/
[Llama]: https://www.llama.com/
[Llamafile]: https://github.com/mozilla-ai/llamafile
[LLM skills every AI engineer must know]: https://fiodar.substack.com/p/llm-skills-every-ai-engineer-must-know
[Local LLM Hosting: Complete 2026 Guide - Ollama, vLLM, LocalAI, Jan, LM Studio & More]: https://www.glukhov.org/post/2025/11/hosting-llms-ollama-localai-jan-lmstudio-vllm-comparison/
[Looking back at speculative decoding]: https://research.google/blog/looking-back-at-speculative-decoding/
[Mistral]: https://mistral.ai/
[OpenClaw: Who are you?]: https://www.youtube.com/watch?v=hoeEclqW8Gs
[Optimizing LLMs for Performance and Accuracy with Post-Training Quantization]: https://developer.nvidia.com/blog/optimizing-llms-for-performance-and-accuracy-with-post-training-quantization/
[Run LLMs Locally: 6 Simple Methods]: https://www.datacamp.com/tutorial/run-llms-locally-tutorial
[SEQUOIA: Serving exact Llama2-70B on an RTX4090 with half-second per token latency]: https://infini-ai-lab.github.io/Sequoia-Page/
[Sleeper Agents: Training Deceptive LLMs that Persist Through Safety Training]: https://arxiv.org/abs/2401.05566
[What are Language Models in NLP?]: https://www.geeksforgeeks.org/nlp/what-are-language-models-in-nlp/
[What is chain of thought (CoT) prompting?]: https://www.ibm.com/think/topics/chain-of-thoughts
