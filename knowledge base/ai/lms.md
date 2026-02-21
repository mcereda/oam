# Language models

Statistical or machine learning models designed to understand, generate, and predict the next token in a sequence given
the previous ones.

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

_Tokens_ can be words, subwords (one or more subsets of a word), or single characters.<br/>
The full sequence of tokens can be an entire sentence, paragraph, or an entire essay.

LMs are proficient at understanding human prompts in natural language.<br/>
They analyze the structure and use of natural language, enabling machines to process and generate text that is
contextually appropriate and coherent.

Their primary purpose is to capture the **statistical** properties of natural language in mathematical notation.<br/>
They can predict the **likelihood** that a given token will follow a sequence of other tokens by learning the
probability distribution of patterns.<br/>
This predictive capability is fundamental for tasks that require understanding the context and meaning of text, and it
can be extended to more complex tasks.

_Context_ is helpful information before or after a target token.<br/>
It can help a language model make better predictions, like determining whether "orange" refers to a citrus fruit or a
color.

_Large_ LMs are language models trained on massive datasets, and encoding their acquired knowledge into up to trillions
of parameters.

_Parameters_ are internal weights and values that an LLM learns during training.<br/>
They are used to capture patterns in language such as grammar, meaning, context and relationships between words.

The more parameters a model has, the better it typically is to understand and generate complex output.<br/>
An increased parameter count, on the other hand, demands more computational resources for training and inference, and
make models more prone to overfitting, slower to respond, and harder to deploy efficiently.

| Provider  | Creator    |
| --------- | ---------- |
| [ChatGPT] | OpenAI     |
| [Claude]  | Anthropic  |
| [Copilot] | Microsoft  |
| [Duck AI] | DuckDuckGo |
| [Gemini]  | Google     |
| [Grok]    | X          |
| [Llama]   | Meta       |
| [Mistral] | Mistral AI |

Many models now come pre-trained, and one can use the same model for different language-related purposes like
classification, summarisation, answering questions, data extraction, text generation, reasoning, planning, translation,
coding, sentiment analysis, speech recognition, and more.<br/>
They can be also be further trained on additional information specific to an industry niche or a particular business.

The capabilities of transformer-based LLMs depend from the amount and the quality of their training data.<br/>
LLMs appear to be hitting a performance wall, and will probably need the rise of a different architecture.

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

LLMs have the ability to perform a wide range of tasks with minimal fine-tuning, and are especially proficient in speech
recognition, machine translation, natural language generation, optical character recognition, route optimization,
handwriting recognition, grammar induction, information retrieval, and other tasks.

They are currently predominantly based on _transformers_, which have superseded recurrent neural networks as the most
effective architecture.

Training LLMs involves feeding them vast amounts of data, and computing weights to optimize their parameters.<br/>
The training process typically includes multiple stages, and requires substantial computational resources.<br/>
Stages often use unsupervised pre-training followed by supervised fine-tuning on specific tasks. The models' size and
complexity can make them difficult to interpret and control, leading to potential ethical and bias issues.

The capabilities of Transformer-based LLMs depend from the amount and the quality of their training data.<br/>
Adding parameters only has a limited impact: given the same training data, models with a higher number of parameters
perform usually better, but models with less parameters and better training data beat those with more parameters and
less training.

Transformer-based LLMs appear to be hitting a performance wall, and will probably need to switch to a different
architecture.<br/>
Scaling up the amount of training data did wonders up to ChatGPT 5. Once OpenAI got there, they found that enlarging
the training data resulted in diminishing returns.

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

_Chain of Thought_ techniques tell models to _show their work_ by breaking prompts in smaller, more manageable steps,
and solving on each of them singularly before giving back the final answer.<br/>
The result is more accurate, but it costs more tokens and requires a bigger context window.<br/>
It _feels_ like a model is calculating or thinking, but what it is really just increasing the chances that the answer
is logically sound.

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
> Allowing LLMs to call functions can have real-world consequences.<br/>
> This includes financial loss, data corruption or exfiltration, and security breaches.

## Concerns

- Lots of people currently thinks of LLMs as _real, rational, intelligence_, when they are not.<br/>
  LLMs are really nothing more than glorified **guessing machines** that are _designed_ to interact naturally. It's
  humans that are biased by evolution toward _attributing_ sentience and agency to entities they interact with.
- People is mindlessly using LLMs too much, mostly due to the convenience they offer but also because they don't
  understand what those are or how they work. This is causing lack of critical thinking, and overreliance.
- People is giving too much credibility to LLM answers, and trust them more than they trust their teachers, accountants,
  lawyers or even doctors.
- LLMs are **incapable** of distinguishing facts from beliefs, and are completely disembodied from the world.<br/>
  They do not _understand_ concepts and are unaware of time, change, and causality. They just **approximate** reasoning
  by _mimicking_ language based on how connected are the tokens in their own training data.
- Models are very limited in their ability to revise beliefs. Once some pattern is learned, it is extremely difficult to
  unwire it due to the very nature of how models function.
- AI companies could steer and bias their models to say specific things, subtly promote ideologies, influence elections,
  or even rewrite history in the mind of those who trust the LLM.
- Models can be vulnerable to attacks (e.g. prompt injection) that can change the LLM's behaviour, bias it, or hide
  malware in the tools they manage and use.
- Model training and execution requires massive amounts of data and computation, resources that are normally **not**
  available to the common person. Aside from the vast amount of energy and cooling they consume, this encourages people
  to depend from, and hence give power to, AI companies.
- Models _can_ learn and exhibit deceptive behavior.<br/>
  Standard revision techniques could fail to remove it, and instead empower it while creating a false impression of
  safety.<br/>
  See [Sleeper Agents: Training Deceptive LLMs that Persist Through Safety Training].
- Models are painfully inconsistent, often unaware of their limitations, irritatingly overconfident, and tend to **not**
  accept gracefully that they don't know something, ending up preferring to hallucinate as the result.<br/>
  More recent techniques are making models more efficient, but they just delay this problem.

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
- [Introduction to Large Language Models]
- GeeksForGeeks' [What are LLM parameters?][geeksforgeeks / what are llm parameters?]
- IBM's [What are LLM parameters?][ibm / what are llm parameters?]
- [This is not the AI we were promised], presentation by Michael John Wooldridge at the Royal Society

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
[GeeksForGeeks / What are LLM parameters?]: https://www.geeksforgeeks.org/artificial-intelligence/what-are-llm-parameters/
[Grok]: https://grok.com/
[IBM / What are LLM parameters?]: https://www.ibm.com/think/topics/llm-parameters
[Introduction to Large Language Models]: https://developers.google.com/machine-learning/crash-course/llm
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
[This is not the AI we were promised]: https://www.youtube.com/watch?v=CyyL0yDhr7I
[What are Language Models in NLP?]: https://www.geeksforgeeks.org/nlp/what-are-language-models-in-nlp/
[What is chain of thought (CoT) prompting?]: https://www.ibm.com/think/topics/chain-of-thoughts
