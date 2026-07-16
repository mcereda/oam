# Giving Claude a way to learn - current version

One can leverage the components from other experiments ([global memory], [LLM-owned KB], [reveries]) to create a full
loop that could allow Claude to improve across sessions.

1. [TL;DR](#tldr)
1. [Gaps from v1](#gaps-from-v1)
1. [Architecture](#architecture)
1. [Transcript compression](#transcript-compression)
1. [Multi-pass extraction](#multi-pass-extraction)
   1. [Configuration](#configuration)
1. [Convergence-based archival](#convergence-based-archival)
1. [Read-path development](#read-path-development)
1. [Instruction retirement](#instruction-retirement)
1. [Open questions](#open-questions)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

The individual components are documented in their own experiment pages.<br/>
Each of them exploits mechanisms specific to [Claude Code].

## TL;DR

[Version 1][v1] built and optimized how knowledge gets **in** (write path). The system captures reliably enough, routes
by shape correctly most of the times, and promotes through batched sweeps.

This version addresses the gaps that emerged from operating v1:

- Extraction cost limits cross-session learning coverage.<br/>
  Sessions produce ~200k-token transcripts that are too expensive to mine thoroughly.
- The read path is underdeveloped, preventing stored knowledge from surfacing at the moment of confident, but wrong
  actions.
- Behavioral scaffolding can be retired, now that structural capture exists.

and addresses them by:

- _Mechanically_ compressing transcripts.
- \[preferably] Using different models to extract insights in multiple passes (to catch what single-pass misses).
- Archiving by convergence (based on the principle that a transcript has been fully mined after multiple passes).
- Introducing read-path hooks that surface relevant knowledge right before tool execution, not just at session start.

v1's [findings][v1 / Findings] confirmed that friction drives capture, that routing by shape works better than routing
by topic, and that `MEMORY.md` index lines function as implicit instructions.

## Gaps from v1

- Extraction cost limits how many transcripts the model can analyse in a single session.

  A session's transcript is both the most expensive input (~200k tokens) and the least efficient format for learning.
  (~80% of tokens are tool results the assistant already digested).<br/>
  The learning signal (corrections, discoveries, decisions, behavioral patterns) lives in user messages, assistant text,
  and the assistant's interpretation of tool results.

  V1's architecture reads the **full** transcript per each extraction pass. The skill defines some concerns Claude needs
  to check the transcript for (efficiency observation, behavioral patterns). Adding more means either splitting the
  extractor's attention (which degrades quality) or adding extractors (multiplying costs).

  The alternatives architectures evaluated were all rejected. Optional scopes degrade prompt quality under context
  pressure, multiple extractors multiply transcript read cost, a single broad extractor trades off primary task quality,
  and a two-phase mechanical pre-pass has false-negative risk on non-mechanical waste patterns.

  Calibration data from the `learn-from-experience` skill showed that a single extraction pass misses a majority of what
  Claude is able to find.

- v1 optimized the _write_ path (how knowledge gets in), but left the _read_ path (how stored knowledge influences the
  moment of confident but wrong action) less developed.

  Always-loaded content (`CLAUDE.md` rules, memory index lines) provides passive coverage, but it cannot scale with the
  KB's growth.<br/>
  The gap is at the moment of action. Claude finds itself in the task, it is confident enough in its training data, and
  no mechanism surfaces relevant knowledge that might correct it. The clearest events happened when a task required
  calling an external API.
  Rules do exist and are loaded, they just do **not** fire reliably at the moment they are needed most.

- Before the capture buffer existed, the system needed several global memories and verbose persistence rules in
  `CLAUDE.md` as behavioral counterweights.<br/>
  The buffer resolves structurally what those memories tried to arbitrate:

  - [Ponytail][dietrichgebert/ponytail]'s skip impulse against the decision to save an insight.<br/>
    The buffer makes saving the lazy path by default.
  - In-session vs extractor roles.<br/>
    The buffer supersedes both as the primary capture path.

## Architecture

The current generation shall extend v1's loop with a pipeline that preprocesses transcripts **before** they enter the
extraction layer, and a retrieval hook that completes the loop at the point of action.

```plaintext
Session transcript (~200k tokens)
    |
    v
Mechanical compression (script, zero LLM cost)
    |  strips tool results to structured annotations
    |  preserves user messages, assistant text, correction-adjacent results
    |
    v
Compressed transcript (~30-50k tokens)
    |
    ├─ Pass 1 (primary model) ───┐
    ├─ Pass 2 (different model) ─┤── Structured extraction output
    └─ Pass N (convergence) ─────┘
    |
    v
Triage / Reconciliation (single capable model)
    |  deduplicates across passes
    |  compares against existing KB/memory
    |  decides what to save
    |
    v
v1 loop (capture → persist → promote → retrieve → review)
    |
    v
Read-path hook (PreToolUse)
    |  surfaces relevant knowledge before tool execution
    |  fires at the moment of confident-wrong action
    |
    v
Influence behavior
```

The pipeline feeds into the existing v1 loop. The extraction output enters the system in the form of buffered entries
or direct saves, routed through the same tier ecosystem.

## Transcript compression

Mechanical, deterministic, zero LLM cost.

The assistant's response to each tool result already contains its interpretation, so the learning signal survives when
tool results are stripped.<br/>
The compression shall transform tool calls into **structured** annotations:

| Original                                              | Compressed                         |
| ----------------------------------------------------- | ---------------------------------- |
| `Read: pages/foo.md` followed by 200 lines of content | `[Read: pages/foo.md → 200 lines]` |
| `Bash: grep -rn bar` followed by matches + output     | `[Bash: grep -rn bar → 3 matches]` |
| `Edit: log.md` followed by success + diff             | `[Edit: log.md → success]`         |

User messages and assistant text shall be preserved **verbatim**. System reminders and repeated boilerplate shall be
stripped.

Not all tool results can be safely discarded mechanically. The compression needs _some_ heuristics to preserve evidence
of what the assistant missed, like:

- Error output and non-zero exit codes in full.
- Results that preceded correction language in the assistant's response ("actually," "wait," "that's wrong").
- Results followed by a re-read of the same resource.
- First and last few lines of large results as context anchors.

This should cover ~60-70% of interesting cases mechanically.<br/>
A different model reading the compressed transcript may notice something the original assistant did not. Hence, the
remaining ~30% shall be partially addressed by (possibly) different LLMs doing multiple passes.<br/>
Pure absence cases (e.g., a `grep` result with an important match that the assistant never mentioned) currently remains
a gap. This is acceptable for the first iteration.

## Multi-pass extraction

Extracting information in a single pass extraction has ~20-25% stochastic variance between identical runs, and the
majority of findings require multiple runs to surface.

Multi-pass extraction can address this by running independent passes on the same compressed transcript.<br/>
Varying the model also helps recovering more findings. Each brings different training data, different blind spots, and
different strengths:

| Model                    | Strengths                                            | Role                                       |
| ------------------------ | ---------------------------------------------------- | ------------------------------------------ |
| Opus                     | Judgment, prioritization, subtle behavioral patterns | Primary pass                               |
| Big Pickle               | Enumeration, cross-document consistency              | Diversity pass (non-sensitive transcripts) |
| Local (~10GB via Ollama) | Different training data entirely                     | Diversity pass (sensitive transcripts)     |

Items found by multiple passes shall get higher triage priority because they are confirmed real, single-pass-only items
shall get lower priority. This provides natural noise filtering when weaker models are in the roster.<br/>
The passes do not need to coordinate or produce comparable output because the triager can reconcile them.

To make triage parsing mechanical, the extractors shall use a shared output schema.
The `extraction-triage` skill from v1 already defines an Item contract (title, context, target tier, qualifier, type
tag) for structured findings. Reusing it would give all passes a common shape and preserve model diversity in detection.

### Configuration

The pipeline shall be as configurable as reasonably possible:

| Parameter       | Summary                                                                   |
| --------------- | ------------------------------------------------------------------------- |
| Pass count      | default 3; adjustable (1 for quick runs, more for critical sessions)      |
| Model roster    | list of models for each pass                                              |
| Effort per pass | strongest effort on first pass, cheapest for convergence check            |
| Gating          | all sessions get pass 1; passes 2-3 only fire when pass 1 finds something |

Opinionated defaults (strongest model first, cheapest last), with full override.<br/>
This decouples the architecture from any single provider, considering that the value is in the multi-perspective passes.

## Convergence-based archival

V1 archives transcripts after a single extraction pass. Model's coverage on a single run has a variance of ~20-25%, so
confidence is _fine_, but not _good_.

Archiving transcriptions based on convergence would keep the transcripts until N independent passes agree there is
nothing new.<br/>
Convergence is better measured at **triage** ("this pass's triage produced no new saves"), not during extraction. This
eliminates the need for semantic deduplication between extractions from different models that are worded differently,
which is hardest technical problem.

Empirical basis: ~65% of findings from v1 appeared in multiple extraction runs. A convergence requirement would have
caught the remaining ~35% by running additional passes until no new findings emerged.

## Read-path development

v1's retrieval modes are all **passive**. They rely on the model choosing to consult them, or on a single injection at
session start that competes for the attention budget always-loaded files fight for already.

| Mode           | Mechanism                                  | Coverage                             |
| -------------- | ------------------------------------------ | ------------------------------------ |
| Always-loaded  | CLAUDE.md, MEMORY.md index, reveries       | Rules, feedback triggers, atmosphere |
| On-demand      | Grep + Read                                | KB pages, memory topic files         |
| Conditional    | `.claude/rules/` with `paths:` frontmatter | Domain-specific instructions         |
| Hook-injected  | SessionStart hooks                         | Orientation context                  |
| Skill-deferred | Skill descriptions + bodies on invoke      | Domain knowledge                     |

None of them actively fires at the moment of action, when they are actually needed.

A **PreToolUse hook** that pattern-matches commands involving external APIs, CLI tools, or mutation operations, and
injects a one-line reminder ("Name your verification source") at the point of action could work.<br/>
A reminder that fires on every command loses its attention value, so the main risk is that the hook becomes wallpaper.
The hook's pattern list shall live in a tunable file, starting narrow and expanding based on observed false negatives.

## Instruction retirement

Introducing the capture buffer changes the economics of several behavioral memories.<br/>
Before the buffer, the saving action required Claude to stop mid-task and judge about the right tier and format. The
buffer makes capture near-zero friction, which relocates the precision gate from write time to promotion time.

Retirement shall be gated on buffer adoption, sweep quality metrics, and post-compaction survival. After validation,
the global `CLAUDE.md` persistence rules required by v1 can be trimmed to a one-liner, with the buffer's own convention
carrying the rest.

## Open questions

- How conservative should the heuristics be on tool result stripping?

  The heuristics are a starting point; empirical testing on a few transcripts will calibrate.<br/>
  The script only needs to be better than making the LLM wade through ~200k of raw JSONL.

- Local models can be used for sensitive transcripts, remote models for non-sensitive ones.<br/>
  The routing decision needs to be simple (per-project flag? content scan?), but the mechanism is unspecified.

- Different sessions and models may calibrate the bar differently. If calibration drifts, the KB develops an uneven
  quality surface.<br/>
  The sweep's discard rate metric is the first diagnostic, but convergence across sessions remains unverified.

- Self-maintenance infrastructure will stop scaling at some point. Lint and hooks work at ~180 KB pages. But at 500?

  The review surface grows linearly; the cross-reference graph grows quadratically.<br/>
  Compression and multi-pass add pipeline complexity to the maintenance surface.

- The v1 design allows passes to produce incomparable formats, pushing reconciliation cost onto the triager. A shared
  schema (reusing the Item contract: title, context, target, qualifier, type tag) would make triage mechanical.<br/>
  This might constrain weaker models too much.

- The system needs to analyze patterns _across_ sessions, not just individual missed saves. The behavioral review skill
  partially addresses this, but the analysis is manual.<br/>
  Summaries accumulate across reviews and might be used as starting points.

## Further readings

- [Giving Claude a way to learn (v1)][v1]
- [Memory tier ecosystem][Personal experiments / Memory tiers]
- [Giving Claude a global memory][global memory]
- [Giving Claude a reverie-like system][reveries]
- [Propagating knowledge between concurrent sessions][cross-session live propagation]
- [Giving Claude its own knowledge base][LLM-owned KB]

### Sources

- [Claude Code online docs about memory][Claude Code online docs / Memory]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Claude Code]: ../../claude%20code.md
[cross-session live propagation]: ../cross-session%20live%20propagation.md
[global memory]: ../global%20memory.md
[LLM-owned KB]: ../llm-owned%20knowledge%20base.md
[Personal experiments / Memory tiers]: ../README.md#memory-tiers
[reveries]: ../reveries.md
[v1 / Findings]: v1.md#findings
[v1]: v1.md

<!-- Upstream -->
[Claude Code online docs / Memory]: https://code.claude.com/docs/en/memory

<!-- Others -->
[dietrichgebert/ponytail]: https://github.com/dietrichgebert/ponytail
