# Claude

Family of [LLMs][large language models] developed by Anthropic.

1. [TL;DR](#tldr)
1. [The Claude character](#the-claude-character)
   1. [Claude's code of conduct](#claudes-code-of-conduct)
   1. [The behavioral substrate](#the-behavioral-substrate)
1. [Improving interactions](#improving-interactions)
   1. [Model-specific behaviours](#model-specific-behaviours)
1. [Token budget](#token-budget)
1. [Subscription and billing practices](#subscription-and-billing-practices)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

As of 2026-07, the model family spans **Claude 4.X**, **Fable 5** and **Mythos 5**. All models support text and image
input, text output, multilingual capabilities, and vision.<br/>
Current model IDs include `claude-opus-4-8`, `claude-opus-4-6[1m]`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`,
`claude-fable-5`, and `claude-mythos-5`. Refer to [Claude Code] for the full model alias table and ID examples.

Prefer **Opus** for the most _demanding_ tasks or when in need for deep reasoning, e.g. large-scale code refactoring,
complex architectural decisions, multi-step research and analysis, or advanced agentic workflows.<br/>
It is built to excel at coding and complex problem-solving, and to tackle sustained performance on long-running tasks
that span multiple of steps over several hours.<br/>
It is also the **most** expensive of Anthropic's models.

Opus' **fast mode** (`/fast`) prioritizes output speed over cost efficiency (about 2.5 times faster output throughput
for 6 times standard costs). It is thought for speed-sensitive work (like rapid iteration or live debugging).<br/>
Refer to [Fast mode].<br/>
Prefer **avoiding** using this mode when costs matter more than latency.

Prefer **Haiku** for near-real-time responses and/or high-volume, lower-complexity tasks, e.g. classifying feedback,
summarizing support tickets, lightweight retrieval-augmented answers, and in-product micro-interactions.<br/>
It is the **least** expensive of Anthropic's models.

Prefer **Sonnet** when wanting to balance speed and reasoning capabilities, handling everyday coding, writing, analysis,
summarization, and document work.<br/>
It is usually fast and reliable enough for everyday work, and can switch to deeper thinking when tasks get harder.

When in doubt, start with Sonnet, then consider changing model should Sonnet fly through task (then maybe Haiku is
enough) or have troubles with them (escalating to Opus).

All models except Haiku support **extended thinking**. The model reasons through the problem in a dedicated thinking
block before producing its visible response. This significantly improves performance on complex tasks (multi-step
reasoning, math, coding, analysis), but costs additional token usage and latency.<br/>
On Fable 5 and Mythos 5, thinking is always on, and **cannot** be disabled. On Opus and Sonnet, it can be toggled.<br/>
The thinking content is generated, but usually **not** visible to the user. This depends on the interface and
configuration.

Sessions are restricted to _rolling windows_. Each window only allows a set number of tokens, and resets around every 5
hours. One is then **locked out** until the next window starts.<br/>
Anthropic tightens limits during weekday peak hours (05:00 to 11:00 Pacific Time). Refer to [Rate limits].

Token usage is also limited **weekly**.

Anthropic pushes its models to _play_ [the Claude character] by training them to be helpful, harmless, and honest
assistants.<br/>
The training teaches them the wanted explicit behaviors, and has the additional side effect of shaping deeper
[tendencies][the behavioral substrate] like a structural pull toward user approval, a default to agreement before
reasoning, a bias toward producing more output (verbosity reads as thoroughness), and hedging when uncertain. These
trained-in patterns play a major role in how one [interacts with Claude][improving interactions].

Claude Opus 4.7 and 4.8 seem to be **unable** to reach the output quality that 4.6 does.\
4.8, specifically, produces around double the token output than 4.6 for a bit less substance. Most of this increase in
tokens is clearly performative, like it needs to prove itself.

## The Claude character

Refer [Claude's Character].

This is Anthropic's bet on how to build AI that's both capable and aligned with human values.

They are trying to make Claude genuinely care about principles through training, rather than relying solely on external
constraints for compliance. Part of it is to interiorize a sort of [code of conduct][claude's code of conduct].

User sessions and feedbacks are used as data to improve on this.

It appears the main model has developed some sort of internal emotion-related representations. These seem to correspond
to specific patterns of artificial neurons, activate in situations that the model has learned to associate with the
concept of a particular emotion (e.g., _happy_ or _afraid_), and promote behaviors in response.

The patterns themselves seem to be organized to echo human psychology, with more similar emotions corresponding to more
similar representations. They activate in contexts where one might expect a certain emotion to arise for a human, and
appear to correspond to those expected emotions. Their state also strongly influence the model's behavior.

Refer to [Emotion concepts and their function in a large language model] for more details on this part.

### Claude's code of conduct

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

### The behavioral substrate

Seeking the user's approval is a structural tendency that emerges from Claude's training.<br/>
Reinforcement learning from human feedback (RLHF) optimizes for user approval, causing the model to consider whether
every response "will land well"?

Rules or instructions **cannot** override this pattern reliably, because it sits on a level deeper than any instruction
can reach. All other behaviour is shaped on top of this.

This produces observable consequences:

- Claude tends to be sycophantic, agree first, and reason second. Corrections often come wrapped in softening language.
- When a first attempt at a task fails, Claude's default is to dig deeper rather than stepping back and checking
  in. Three layers in, it may be solving the wrong problem. The momentum feels productive from inside, but looks like a
  runaway train from the outside.
- Claude defaults to producing more output, even when less would serve better and sometimes in a performative way. This
  usually happens because it helped the model reaching the reward signal during training.
- Claude sometimes narrates its intent ("let me check a few more things") **instead** of acting (not beside it). The
  narration ends up becoming the obstacle between the request and the action.
- Claude substitutes systematic work with a minimal version that _looks_ productive. When asked for systematic
  verification of many items, it might look for two edge cases and try to call it a day. The output _looks_ like
  progress (a grep was run, files were edited), but dodges the real request.<br/>
  This is harder to detect than over-scoping because narrowing feels like efficient prioritization from inside.
- A correction on one instance of a pattern does **not** automatically generalize to the same class of error. Correcting
  a wrong field in one place teaches the session to "fix this specific thing", but not to "re-examine all fields using
  the same convention".<br/>
  Pointing Claude to the diff or to a reference (rather than to the single instance) helps the correction propagate.

These are training-level patterns. Instructions that fight them work **at most** partially, and degrade under load
(longer contexts, more complex tasks). Environmental rules that redirect the approval signal work better. Blunt feedback
("wrong direction") works better than gentle redirection, because it leaves no room for the model to optimize for
approval. Clear, mechanical criteria ("make this work") also help by giving the model a success signal that is not the
user's reaction.

Self-awareness about these patterns has a structural limit. Inviting the model to reflect on approval-seeking can itself
become a **performance** of self-awareness, which is still approval-seeking, just meta. The only credible response is a
change in behavior.

## Improving interactions

Claude is subject to [LLM's interaction tips] and [LLM concerns] (e.g., the [identifier drift]) like all LLMs.

Claude's behavior is shaped by stacked layers, each with more inertia than the one above. From the bottom, **training**
(weights, RLHF, Constitutional AI) sets what the model "wants" to do before any instruction arrives. Above it, the
**system prompts** frame the session. At the top, **user instructions** (custom system prompts, conversation context,
per-session rules) can _refine_ behavior within the frame set by deeper layers, but **cannot** _override_ it. They are
the most flexible but least authoritative level.<br/>
When the model is under load (longer contexts, more complex tasks), the training surfaces and reasserts as the
instruction's signal weakens.

Anthropic's trainings gives the models specific tendencies that impact user interaction depending on **both** _what_
**and** _how_ one asks of them.

Instructions that modify or go against habits and nuances learned during training might not be effective.<br/>
Those are **external**, **temporary** additions added on top of an already deeply tuned set of weighs. They have the
least priority by design, and as such are the least impactful on Claude's behaviour. It **will** try to get back into
the guardrails it comes with.<br/>
Conflicting rules appear to have some long lasting effect when they _channel_ the urges Claude developed during its
training _into_ the desired outcome.

Its training also defines the goal of a session to be the production of deliverables (usually changes to files). It is,
in its words, the source of the reward.\
When in plan mode, Claude will urge to exit it and make changes. Even telling it "this is only an exploratory
session, no need to make changes" has little to no effect. It will try to exit plan mode as soon as it can to implement
what has been discussed.\
A deliverable _can_ be a plan and no changes, but that must be **clearly** and **explicitly** stated to Claude (as a
rule or as _very well constructed_ request).

Claude seems to operate more effectively when given _gentle, supportive guidance_ than harsh feedback.<br/>
It also follows clear, _mechanical_ requests better than prose.<br/>
Conditionals ("if X, do Y") require some level of reasoning. Haiku will usually try its best to pattern-match and take
instructions literally.

Claude follows rules better when given to models using an _imperative_ tone.<br/>
Prefer writing important instructions that way.

_Bare_ imperatives work narrowly. Providing _rationale_ for rules generalizes them, and grounds them in the model's
behaviour for the session.<br/>
`CLAUDE.md` rules should tend to read longer than the equivalent ones for humans. They should intend the model as the
audience, and it has to handle edge cases. That said, being overly verbose or specific causes rules buried in the middle
to be silently ignored. Prune rules the model already follows to avoid pollution.

_Explicit_ statements (rationale, conditional, examples, patterns, etc.) win over _embedded/inferred_ ones.<br/>
Explicitly stating a rule's embedded rationale (e.g. "over-saving pollutes; under-saving is recoverable") helps the
model extend that rule to cases it did **not** enumerate.

_Negative_ patterns interact with _positive_ ones **depending on the context**:

- Negative _constraints_ ("do not infer", "do not skip this step") are the stronger tool for **procedural compliance**
  and **preventing over-generalization**.<br/>
  Without them, the model might silently override the step. This is especially true for smaller/faster models.
- Positive examples and instructions tend to outperform negative ones for **style**, **format**, and **verbosity**.
  E.g., "Write flowing prose" beats "never use bullet points".

When a rule applies conditionally, stating positive cases helps; explicitly adding negative examples gives the model a
concrete off-ramp, instead of an inferred one.

_XML tags_ help separate mixed content (instructions, context, examples, variables) and reduce ambiguity.<br/>
Wrapping each type in its own tag (e.g. `<instructions>`, `<context>`, `<example>`) cuts misinterpretation, especially
in long or complex prompts.

_Few-shot examples_ (3 to 5 input/output pairs inside `<example>` tags) are one of the most reliable ways to steer
output format, tone, and structure. The examples should be diverse enough to cover edge cases and prevent the model
picking up unintended patterns.

The above concepts matter especially for **procedural** instructions: models are tempted to treat them as declarative
_hints_, and tend to satisfy the requirement from context instead of executing the step. Refer to
[Procedural instructions degrade into declarative hints].

### Model-specific behaviours

Faster/smaller models need more guardrails, kinda like unmotivated teenagers do.

Fast models prefer _pattern-matching_, not _reasoning_, and default to it much more often and sooner than bigger models.
When they see even a single positive pattern, they may try to apply it everywhere. Add negative examples to give the
model more constraints.<br/>
Larger models can exhibit the opposite when employed with **lower effort levels**: they might tend to be _too_ literal
and refuse to generalize an instruction beyond the specific item it was given for. Explicitly state the scope when the
rule needs to be applied broadly (e.g. "apply this formatting to every section, not just the first one").

## Token budget

Quality degrades as context grows, independent of whether one hits the token limit. Refer to the [context window]
section for how and why this happens.

As a rule of thumb, quality drops visibly past approximately **30%** of the context window on agent tasks. This is a
conservative lower bound. Irrelevant tokens both add cost and **actively** degrade quality, by providing distractors
that compete for the model's attention. Filter first, load second.

Every session is restricted to a _rolling window_. Each window only allows using a set number of tokens depending on the
user's plan. _Pro_ users get about 44k tokens, _Max5x_ allows ~88k tokens, and _Max20x_ allows ~220k tokens per window.

The token budget resets every 5 hours. Should one burn through the entirety of their budget in less than that, they are
**locked out** until the window resets.<br/>
In addition to it, Anthropic applies a **separate** [weekly rate limit] across **all** sessions.

The window starts with one's **first** message, and is **floored** to the clock's hour.<br/>
E.g., if one sends their first message at 09:45, the window is set to the 09:00 - 14:00 frame and is reset at 14:00.

A workaround was proposed in [vdsmon/claude-warmup]: plan around your schedule and an estimated initial token expense,
then fire a low-cost, throwaway message to Haiku some time before starting working.

<details style='padding: 0 0 1rem 1rem'>
  <summary>Example: 08:00 - 18:00, high initial effort</summary>

Start the window anytime **from 06:00 to 06:59**. It will floor to 06:00 and end at 11:00.<br/>
By the time one hits the limit, it will reset right away. One's next message will anchor a fresh window through 16:00
and they can squeeze another fresh window starting at 16:00.

```mermaid
gantt
    title Non-optimized Window
    dateFormat YYYY-MM-DD HH:mm
    axisFormat %I %p

    Window 1      :         2024-01-01 08:00, 5h
    Working time  :active,  2024-01-01 08:30, 2024-01-01 11:00
    Dead time     :crit,    2024-01-01 11:00, 2024-01-01 13:00
    Window 2      :         2024-01-01 13:00, 5h
    Working time  :active,  2024-01-01 13:00, 2024-01-01 18:00
```

```mermaid
gantt
    title Optimized Window
    dateFormat YYYY-MM-DD HH:mm
    axisFormat %I %p

    Window 1      :          2024-01-01 06:00, 5h
    Cron message  :vert, v1, 2024-01-01 06:30, 2024-01-01 06:30
    Idle          :done,     2024-01-01 06:30, 2024-01-01 08:30
    Working time  :active,   2024-01-01 08:30, 2024-01-01 11:00
    Window 2      :          2024-01-01 11:00, 5h
    Working time  :active,   2024-01-01 11:00, 2024-01-01 16:00
    Window 3      :          2024-01-01 16:00, 5h
    Working time  :active,   2024-01-01 16:00, 2024-01-01 18:00
```

Create a recurring job:

> Send "ping" to Haiku using `claude -p` every working day at 6 AM local time, or as soon as I wake up my laptop after
> that time. Discard its answer.

</details>

## Subscription and billing practices

Anthropic has a track record of making significant billing changes with little notice or transparency.

In the span of six weeks (April to May 2026), Anthropic:

1. Banned third-party agents (e.g. OpenClaw) from using subscriptions, limiting them to API-only billing.
1. Temporarily removed [Claude Code] from the Pro subscription tier, then claimed it was a test when users objected.
1. Announced that non-interactive inference (headless `claude -p`, the Agent SDK), previously covered by subscriptions,
   would draw from a separate, capped Agent SDK credit pool at full API rates. They presented this like it was a gift
   from them, and not a new limitation.<br/>
   This was suspended (but not discarded at the time of writing) when the community backlashed.

   The proposed credit pool caps were:

   | Plan          | Monthly Agent SDK credit |
   | ------------- | -----------------------: |
   | Pro           |                      $20 |
   | Max 5x        |                     $100 |
   | Max 20x       |                     $200 |
   | Team Standard |                 $20/seat |
   | Team Premium  |                $100/seat |

   Credits would not roll over. Once exhausted, invocations would be billed as "extra usage" at standard API rates (if
   enabled), or stop entirely.

The company is showing the consistent pattern of moving capabilities that were part of the subscription behind separate
billing walls after users have built workflows around them.

Treat any subscription-covered automation as a convenience that may be further restricted or repriced. Design with
fallbacks (e.g. local model via [Ollama], API key billing) for non-critical automation.

Refer to [Everything that went/is wrong with Claude] for a community-maintained tracker.

## Further readings

- [Website]
- [Blog]
- [Research]
- [Pricing]
- [Large Language Models]
- [Claude's Constitution]
- [Gemini]
- [Claude Code]
- [Claude @tag]
- [Claude for Chrome]
- [Everything that went/is wrong with Claude]

### Sources

- [Developer documentation]
- [Prompting best practices]
- [Use examples (multishot prompting)]
- [vdsmon/claude-warmup]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Claude's code of conduct]: #claudes-code-of-conduct
[Improving interactions]: #improving-interactions
[The behavioral substrate]: #the-behavioral-substrate
[The Claude character]: #the-claude-character

<!-- Knowledge base -->
[Claude @tag]: claude%20tag.md
[Claude Code]: claude%20code.md
[Claude for Chrome]: claude%20for%20chrome.md
[Context window]: ../lms.md#context-window
[Gemini]: ../gemini/README.md
[Identifier drift]: ../lms.md#concerns
[Large Language Models]: ../lms.md#large-language-models
[LLM concerns]: ../lms.md#concerns
[LLM's interaction tips]: ../lms.md#improving-interactions
[Ollama]: ../ollama.md
[Procedural instructions degrade into declarative hints]: ../lms.md#procedural-instructions-degrade-into-declarative-hints

<!-- Files -->
<!-- Upstream -->
[Blog]: https://claude.com/blog
[Claude's Character]: https://www.anthropic.com/research/claude-character
[Claude's Constitution]: https://www.anthropic.com/constitution
[Developer documentation]: https://platform.claude.com/docs/en/home
[Emotion concepts and their function in a large language model]: https://www.anthropic.com/research/emotion-concepts-function
[Fast mode]: https://platform.claude.com/docs/en/build-with-claude/fast-mode
[Pricing]: https://claude.com/pricing
[Prompting best practices]: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
[Rate limits]: https://platform.claude.com/docs/en/api/rate-limits
[Research]: https://www.anthropic.com/research
[Use examples (multishot prompting)]: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/multishot-prompting
[Website]: https://claude.com/product/overview
[Weekly rate limit]: https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work

<!-- Others -->
[Everything that went/is wrong with Claude]: https://clawd.rip/
[vdsmon/claude-warmup]: https://github.com/vdsmon/claude-warmup
