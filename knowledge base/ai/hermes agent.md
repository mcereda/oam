# Hermes agent

Self-improving, autonomous [AI agent][AI agents] built by [Nous Research].

1. [TL;DR](#tldr)
1. [Memory](#memory)
1. [Skills](#skills)
   1. [Usage-based lifecycle](#usage-based-lifecycle)
1. [Session lifecycle](#session-lifecycle)
   1. [Background review](#background-review)
   1. [Curator](#curator)
   1. [Session search](#session-search)
1. [Offline evolution](#offline-evolution)
   1. [GEPA](#gepa)
   1. [Fitness evaluation](#fitness-evaluation)
   1. [Skill evolution pipeline](#skill-evolution-pipeline)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Comes with a built-in learning loop to get itself more capable the longer it runs.<br/>
It creates [skills] from experience, improves them during use, nudges itself to persist knowledge, and builds a
deepening model of who it is interacting with across sessions.

Its learning system operates at **runtime** (learning _within_ the main agent) and **offline** (a separate pipeline
optimizes skill text using genetic algorithms).

<details>
  <summary>Setup</summary>

```sh
# Install
pip install 'hermes-agent'

# Run
hermes
hermes --model 'claude-sonnet-4-20250514'
```

</details>

## Memory

Consists of two bounded Markdown files under `~/.hermes/memories/`:

| File        | Purpose                                                      | Size limit |
| ----------- | ------------------------------------------------------------ | ---------- |
| `MEMORY.md` | Agent notes (environment facts, tool quirks, things learned) | 2200 chars |
| `USER.md`   | User profile (preferences, communication style)              | 1375 chars |

Entries are delimited with `§`.<br/>
A single `memory` tool exposes `add`, `replace`, and `remove` actions (substring matching, no IDs).

Both files are injected into the system prompt at session start as a **read-only snapshot**.<br/>
Mid-session writes update the files on disk _immediately_, but _never_ touch the system prompt. This preserves the
prompt prefix cache, and changes become visible on the next session start.

One can plug external memory providers via `MemoryProvider`. Only one provider can be active at a time.<br/>
Supports Honcho ("dialectic user modeling"), Hindsight, and Mem0.<br/>
The provider `initialize()`s, then `prefetch(query)`es per turn, `sync_turn(user, asst)` post-turn `on_session_end()`.

The LLM decides what to remember, nudged by periodic [background reviews][background review].

## Skills

Stored at `~/.hermes/skills/<category>/<skill-name>/SKILL.md` with optional `references/`, `templates/`, `scripts/`,
and `assets/` directories.<br/>
YAML frontmatter with `name`, `description` (enforced <=60 chars), `version`, and `tags`.

Always loads skills' metadata; only loads their full content on demand via `skill_view` (progressive disclosure).

Created in one of two ways:

1. Explicitly, via the `/learn <description>` command.

   Builds a prompt that instructs the agent to gather sources (files, URLs, conversation history) using existing tools,
   then author a skill via `skill_manage`.<br/>
   Supports small (single `SKILL.md`) and large sources (knowledge-base layout with lean index + per-chapter
   `references/` files).

1. Autonomously, via [background reviews][background review].

   After every N tool iterations (configurable `creation_nudge_interval`, default 10), the agent is nudged to consider
   saving skills.

Skills self-improve via `skill_manage` actions `patch` (targeted find-replace) and `edit` (full rewrite).<br/>
Background review can evolve skills it has read (provenance-gated via `tools/skill_provenance.py`).

### Usage-based lifecycle

Tracked in `.usage.json`:

| State              | Trigger                                   |
| ------------------ | ----------------------------------------- |
| `active` (default) | Created or recently used                  |
| `stale`            | Unused for >30 days                       |
| `archived`         | Unused for >90 days, moved to `.archive/` |

Pinned skills bypass this transitions. Nothing is deleted automatically.

## Session lifecycle

### Background review

The turn finalizer checks the following nudge counters after each turn:

- `_memory_nudge_interval` (default 10 turns): triggers [memory] review.
- `_skill_nudge_interval` (default 10 tool iterations): triggers [skills] review.

When either fires, `_spawn_background_review()` launches a daemon thread. In it, a forked `AIAgent` replays the
conversation snapshot and asks "should any skill/memory be saved or updated?"<br/>
The fork is tool-whitelisted to memory + skill management tools only.

Runs on the main model by default (which reuses warm prompt cache). Can be routed to a cheaper auxiliary model (which
uses a compact digest instead).<br/>
Writes go directly to disk.

### Curator

It's a separate background process running on idle (default every 7 days, after 2+ hours idle).<br/>
Uses an auxiliary model to review agent-created skills. Can pin, archive, consolidate, or patch.<br/>
Only touches agent-created skills. Persists state in `.curator_state`.

### Session search

SQLite FTS5 full-text index over all past session messages with 0 LLM cost.<br/>
Can run in _discovery_ mode (FTS5 query), _scroll_ mode (anchored window), or _browse_ (recent sessions) mode.

## Offline evolution

Defined in the [hermes-agent-self-evolution] repository.

It's a standalone optimization pipeline that operates on the Hermes agent by changing its code.<br/>
No GPU training involved, everything is API calls mutating text.

Five phases planned. Currently, only Phase 1 (skill evolution) is implemented.

### GEPA

Genetic-Evolutionary Prompt Adaptation (ICLR 2026 Oral).<br/>
A [DSPy] optimizer treats skill instruction text as an optimizable parameter.<br/>
The repo wraps GEPA; the optimizer source lives in DSPy itself (`dspy>=3.0.0`).

GEPA receives execution traces from `batch_runner` (hermes-agent's parallel eval harness).<br/>
It reads the full agent trajectory (tool calls, reasoning, outputs). The goal is to understand _why_ things fail and
propose targeted mutations.

Falls back to `dspy.MIPROv2(auto="light")` if GEPA is unavailable.

### Fitness evaluation

**Cheap heuristic** checks the keyword overlap between expected behavior and agent output. The score is calculated as
`0.3` + `0.7 * overlap_ratio`.<br/>
Used during optimization iterations for speed.

**LLM-as-judge** scores on the following dimensions:

| Dimension           | Weight |
| ------------------- | ------ |
| Correctness         | 0.5    |
| Procedure following | 0.3    |
| Conciseness         | 0.2    |

Adds a length penalty ramping from 0 at 90% of max size to 0.3 at 100%+. The composite score is calculated as
`max(0, weighted_raw - length_penalty)`.<br/>
Also returns textual `feedback` for GEPA's reflective analysis.

### Skill evolution pipeline

The `SkillModule` class wraps a `SKILL.md` file as a `dspy.Module`. The skill's body becomes the optimizable parameter.
A forward pass injects skill text as `skill_instructions` into a `dspy.ChainOfThought(TaskWithSkill)` signature.

The evolution loop progresses as follows:

1. Load a skill, parse its frontmatter from body.
1. Build the eval dataset (synthetic, golden JSONL, or session mining).
1. Validate the baseline against the constraints.
1. Create `SkillModule(skill_body)`, configure DSPy.
1. Run `dspy.GEPA` (or MIPROv2 fallback); GEPA mutates the skill text.
1. Extract the evolved text from `optimized_module.skill_text`.
1. Validate the evolved skill against the constraints.
1. Evaluate the baseline against the evolved skill on an holdout set.
1. Save the output (evolved skill, baseline, metrics JSON).

Constraint gates:

- Skill text <= 15KB, tool description <= 500 chars, parameters description <=200 chars (configurable).
- The evolved text must **not** exceed the baseline by more than 20%.
- Artifacts can't be blank or empty.
- The skill must have a YAML frontmatter with `name:` and `description:` fields.

The tests suite shells out to `pytest tests/ -q --tb=no` with 300s timeout, and requires 100% pass.<br/>
Failed constraints result in immediate rejection.

The evaluation datasets come from these sources:

| Source         | Location                         | Signal               |
| -------------- | -------------------------------- | -------------------- |
| Synthetic      | Generated by LLM from skill text | Breadth; cheap       |
| Golden         | Hand-curated JSONL               | Ground truth         |
| Session mining | Agent session histories          | Real-world relevance |

Session mining uses a cheap keyword heuristic pass, scored later for relevance by a LLM.<br/>
Secret detection regex strips API keys/tokens before inclusion.<br/>
Dataset capped at `max_examples` (default 50), split 50/25/25 train/val/holdout.

## Further readings

- [Website]
- [Codebase]
- [OpenClaw][openclaw/openclaw] and its alternatives ([qwibitai/nanoclaw], [nullclaw/nullclaw], others)

### Sources

- [Documentation]
- [DSPy]
- [hermes-agent-self-evolution]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Background review]: #background-review
[Memory]: #memory
[Skills]: #skills

<!-- Knowledge base -->
[AI agents]: agents.md

<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/nousresearch/hermes-agent
[Documentation]: https://hermes-agent.nousresearch.com/docs/
[DSPy]: https://github.com/stanfordnlp/dspy
[hermes-agent-self-evolution]: https://github.com/NousResearch/hermes-agent-self-evolution
[Website]: https://hermes-agent.nousresearch.com/

<!-- Others -->
[Nous Research]: https://nousresearch.com/
[nullclaw/nullclaw]: https://github.com/nullclaw/nullclaw
[openclaw/openclaw]: https://github.com/openclaw/openclaw
[qwibitai/nanoclaw]: https://github.com/qwibitai/nanoclaw
