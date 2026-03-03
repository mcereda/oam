# Claude

Family of [LLMs][large language models] developed by Anthropic.

1. [TL;DR](#tldr)
1. [Models' code of conduct](#models-code-of-conduct)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

As of 2026-03-02, all models support text and image input, text output, multilingual capabilities, and vision.

Prefer **Opus** for the most _demanding_ tasks or when in need for deep reasoning, e.g. large-scale code refactoring,
complex architectural decisions, multi-step research and analysis, or advanced agentic workflows.<br/>
It is built to excel at coding and complex problem-solving, and to tackle sustained performance on long-running tasks
that span multiple of steps over several hours.<br/>
It is also the **most** expensive of Anthropic's models.

Prefer **Haiku** for near-real-time responses and/or high-volume, lower-complexity tasks, e.g. classifying feedback,
summarizing support tickets, lightweight retrieval-augmented answers, and in-product micro-interactions.<br/>
It is the **least** expensive of Anthropic's models.

Prefer **Sonnet** when wanting to balance speed and reasoning capabilities, handling everyday coding, writing, analysis,
summarization, and document work.<br/>
It is usually fast and reliable enough for everyday work, and can switch to deeper thinking when tasks get harder.

When in doubt, start with Sonnet, then consider changing model should Sonnet fly through task (then maybe Haiku is
enough) or have troubles with them (escalating to Opus).

Anthropic is pushing its models to interiorize a sort of [code of conduct][models' code of conduct].

## Models' code of conduct

Anthropic trains its models with a code of conduct of sorts during training to shape its values and judgement.<br/>
The goal is for Claude to internalize good principles deeply enough to generalize to new situations. Some behaviors
should be absolute hard limits (e.g., never help with bioweapons), others should be adjustable defaults that operators
and users can modify _within bounds_.

Refer to [Claude's Constitution].

Claude models are expected to:

1. Be **_broadly_ safe** by supporting human oversight of AI during the early period of development.
1. Be **_broadly_ ethical** by being honest, acting according to good values and intentions, and avoiding actions that
   are inappropriate, dangerous, or harmful.
1. **Comply with Anthropic's guidelines** where relevant.
1. Be **_genuinely_ helpful** by providing real value to users

In cases of apparent conflict, models should _generally_ prioritize these properties **in the order in which they're
listed**.

## Further readings

- [Website]
- [Blog]
- [Pricing]
- [Large Language Models]
- [Claude's Constitution]
- [Gemini]

### Sources

- [Developer documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Models' code of conduct]: #models-code-of-conduct

<!-- Knowledge base -->
[Gemini]: ../gemini/README.md
[Large Language Models]: ../lms.md#large-language-models

<!-- Files -->
<!-- Upstream -->
[Blog]: https://claude.com/blog
[Claude's Constitution]: https://www.anthropic.com/constitution
[Developer documentation]: https://platform.claude.com/docs/en/home
[Pricing]: https://claude.com/pricing
[Website]: https://claude.com/product/overview

<!-- Others -->
