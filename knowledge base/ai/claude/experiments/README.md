# Personal experiments

1. [Memory tiers](#memory-tiers)
   1. [Deciding where memory goes](#deciding-where-memory-goes)
   1. [Alternatives considered](#alternatives-considered)
      1. [Unified tier with shape tags](#unified-tier-with-shape-tags)
      1. [Offload writing to a dedicated `memory-contributor` subagent](#offload-writing-to-a-dedicated-memory-contributor-subagent)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Memory tiers

[Claude Code] ships with **project-scoped** memory only ([Claude Code / auto memory]). Additional memory tiers can build
on top of the building blocks and primitives Claude already uses for it, avoiding the need of external service or vector
databases.

The work that follows _can_ be inspiration for more generic abstractions, but it is currently built **for** use with
Claude Code. Every tier exploits a Claude Code-specific mechanism: global memory loads via `@`-import, reveries and
extraction use `SessionStart` and `SessionEnd` hooks, the 200-line/25KB cap acts as a hard context governor, project
rules resolve via the CLAUDE.md's walk-up-tree, lazy-loading is involved for subdirectory scoping, and write permissions
are imposed via the sandbox model.<br/>
Proposals to improve this system that assume a generic agent framework (auto-triage buffers, semantic retrieval layers,
portable memory stores) **will misfire**, because they try to solve for constraints this system doesn't have while
ignoring the platform features it depends on.

| Tier           | Location                            | Loading                                                                  | What belongs here                      | Source       |
| -------------- | ----------------------------------- | ------------------------------------------------------------------------ | -------------------------------------- | ------------ |
| Project memory | `~/.claude/projects/<repo>/memory/` | First 200 lines or 25 KB of `MEMORY.md` at launch; topic files on demand | Project state, decisions, corrections  | Built-in     |
| Global memory  | `~/.claude/memory/`                 | Via `@`-import in `~/.claude/CLAUDE.md`; same 200-line/25 KB cap         | Cross-project preferences and identity | Experimental |
| Knowledge base | Dedicated git repository            | On demand (`Grep`/`Read`), with hook-based reminders                     | Reusable patterns, gotchas, reference  | Experimental |
| Reveries       | `~/.claude/reveries.md`             | Injected at the start of **every** session via `SessionStart` hook       | Session texture, atmosphere            | Experimental |

> [!important] Reminder: context is **not** memory
> Context files (`CLAUDE.md`, rules) are meant to be **human**-curated and carry instructions Claude should **not**
> diverge from. Memory should be **freely** writable by Claude, accumulate over sessions, and carry **learnings**
> instead of rules.

Routing:

- Store memories by _shape_, not by _topic_.<br/>
  Refer to [AI agents memory tiers][ai agents / memory tiers] and [Deciding where memory goes].
- Use **project memory** for project-specific context, **global memory** for cross-project preferences and insights,
  **Knowledge Bases** (or Wikis) for durable and reusable technical knowledge, and **reveries** for session texture.
- When unsure, write an insight to project memory and consider moving it later. Promotion from a built-in system is
  easier than demotion.

Within each tier, memories benefit from being categorized by **type**. The following types emerged during testing as a
reliable routing heuristic:

| Type        | What belongs here                                              | Examples                                                 |
| ----------- | -------------------------------------------------------------- | -------------------------------------------------------- |
| `user`      | User's role, goals, responsibilities, knowledge                | Role, domain expertise, collaboration preferences        |
| `feedback`  | Guidance the user gave about how to approach work              | Corrections, confirmed approaches, style preferences     |
| `project`   | Ongoing work, goals, initiatives, bugs within a project        | Ticket status, merge freezes, architecture decisions     |
| `reference` | Pointers to where information can be found in external systems | Linear project names, Grafana dashboards, wiki locations |

Recording from **both** failure **and** success matters. If one only saves corrections, the system drifts away from
validated approaches and grows overly cautious. Confirmations are quieter than corrections, and easier to miss because
they are the system doing its job.

Entries benefit from a shared frontmatter scheme (`name`, `description`, `metadata.type`) that keeps them
auditable.<br/>
The `description` field doubles as the index's one-line hook, which allows the routing decision and the entry shape to
stay in sync. Cross-referencing between memories can use a lightweight linking convention (e.g. `[[name]]` where `name`
is another memory's identifier slug). Links to non-existent memories are valid, and signal something worth writing later
instead of errors.

Convention enforcement benefits from a dedicated file (e.g. `CONVENTIONS.md`) that is `@`-included alongside the memory
index. It can codify deduplication rules, promotion signals, and hygiene triggers. This allows loading them alongside
the memories they govern, keeping the main `CLAUDE.md` from growing with memory-specific operational details.

Also see [thedotmack/claude-mem] for an example of automatic, plugin-based memory management system.<br/>
It captures all tool usage, compresses it, stores it in SQLite + ChromaDB, and injects relevant context back via vector
search.<br/>
Compared to the memory tiers, it removes the routing decision entirely by capturing **everything** and retrieving data
**semantically**. The custom file-based approach and claude-mem can be _complementary_: the tiers handle **depth**
(deliberate curation, always-on loading for high-value content, shape-based routing), claude-mem handles **breadth**
(nothing gets lost, automatic capture at scale). The tiers' value is in the judgment calls ("what shape is this
insight?"), claude-mem's is in the wider capture coverage.<br/>
Worth revisiting its integration or as inspiration if the manual routing proves too lossy in practice.

### Deciding where memory goes

When multiple memory surfaces exist (e.g. project memories, a global tier, a knowledge base, a reverie system), routing
and recording insights by _shape_ works better than doing it by _topic_.<br/>
Topics can produce insights of different shapes: a _pattern_ is KB/wiki material, a _correction_ is auto-memory.

Auto-memory and a KB/wiki are legitimately **separate** systems even when the KB is well-scoped:

| Concern (axis) | Auto-memory                              | KB                                                        |
| -------------- | ---------------------------------------- | --------------------------------------------------------- |
| Loading        | Auto-loaded (first 200 lines/25 KB)      | On demand (`Grep`/`Read`)                                 |
| Scope          | Per-repository (shared across worktrees) | Global, tag-filtered                                      |
| Curation cost  | Light-touch, prefers small entries       | Strict: frontmatter, lint, minor entries are frowned upon |
| Decay rate     | Fast (project state changes)             | Slow (technical patterns endure)                          |
| Privacy        | Local-only                               | Pushed to remote, publishable in character                |

Each concern is an _independent_ reason to keep them separate. The KB's character as a public-quality reference depends
on staying exactly that. Mixing user-private memory in it dilutes the pages' value.

<details style='padding: 0 0 1rem 1rem'>

A KB works well for technical reference, which one only needs when working on a specific topic, and fails for concepts
that need to be always in the background like collaboration norms, mid-session corrections that should fire **before**
reaching for the wrong pattern.<br/>
Knowledge that is useless for a session pollutes the context; putting always-on content in the KB requires recreating
some sort of auto-loading mechanism inside the KB, at which point it is just reinventing auto-memory under a different
name.

</details>

Different shapes warrant and require different tiers. A KB legitimately covers cross-project workflow patterns, domain
reference (cloud, language, tool gotchas), reusable synthesis, LLM-collaboration patterns abstracted from any single
user. Auto-memory is more suited for user-private collaboration preferences, project-specific state, mid-session
corrections that are facts (not patterns), identity/profile data.

_Bridging_ different subsystems by promoting content from one to the other matters more than _merging_ them. When a
per-project memory smells like a KB-worthy **pattern** (and not a fact about a single user), it might be worth surfacing
it for promotion. The KB stays a reference, auto-memory stays a scratchpad. Each system retains what makes it good.

**Deduplication** and **promotion** between tiers should follow explicit rules to prevent drift. When a memory
duplicates a rule that already exists in a higher tier (e.g. `CLAUDE.md`), fold unique context into the rule, then
archive and prune the memory. When a correction keeps recurring despite the memory existing, that is the promotion
signal from the lower tier to the higher one. The test is always whether losing the memory on a fresh host would let
the same failure recur.

The same five-axis framework applies whenever one is considering merging **any** two systems. If the axes diverge on
more than one dimension, just keep the systems separate and build a bridge between them instead of merging them into
one.

`CLAUDE.md` vs. auto-memory is a sibling decision driven by the same logic, just with **cross-host portability** as
the discriminator. If a rule needs to fire on a fresh host, before any auto memory has accumulated, it belongs in
`CLAUDE.md` (which is auto-loaded as system context). If not, it belongs in auto memory (project-scoped, accumulated
locally).<br/>
The test should be about cross-host portability, not importance, because a rule can be load-bearing _and_ still be the
right fit for auto memory if losing it on a different host wouldn't let the same failure recur.

**Within** instruction files, rules should make sense on a **freshly configured** machine. References to host-local
resources (KB pages by path, repositories that may have not been cloned, tools that may have not been installed) produce
dangling pointers on a different host. Keep those rules **self-contained** at write time: "see more in document X"
footers belong in tier-local documentation, where the reference is **guaranteed** to resolve.

Different tiers have different scopes and different needs (a set of short markdown files does not require RAG tools),
so each should have their own specialized mechanics.

Memory-system documents must be referenced as `@`-includes, not be put under `.claude/rules/`.<br/>
The memory system is a domain with its own conventions, files, and operational logic (`CONVENTIONS.md`, reveries
guidelines). There are **mechanical** concerns that prevent moving these conventions to `rules/`:

- `MEMORY.md` must be autonomously writable by Claude, and changes every session. This is incompatible with `rules/`'s
  ownership model, which requires humans to curate it. Moving its conventions to `rules/` would separate the convention
  from its subject.
- `@`-includes are **explicit**, and reading `CLAUDE.md` shows exactly what loads and in what order. `rules/`'s loading
  is **implicit** (loads everything in the folder as it finds them), not guaranteeing the order and requiring `ls` to
  audit them.
- `@`-includes place conventions right _next_ to the routing table that references them. `rules/` files load as flat
  peers, with no guaranteed ordering relative to `CLAUDE.md` content.

`rules/` is more adequate for domain-scoped instructions that define working with external systems (e.g. AWS, specific
codebases). `@`-includes are meant for always-on operational content that is part of `CLAUDE.md`'s own contract, which
includes the memory system's governance.

Each tier should also adapt review schedules to its natural cadence, not align to a shared schedule:

| Tier / shape        | Review trigger                                                                                            |
| ------------------- | --------------------------------------------------------------------------------------------------------- |
| Behavioral rules    | "I did X, the rule said Y, the user didn't object". Direct divergence-vs-non-objection.                   |
| Facts (auto-memory) | "I observed something that contradicts the memorized fact". Triggered by epistemic hygiene, fires rarely. |
| Patterns (KB)       | "I solved this differently than the KB says, and it worked". Higher bar: look for repeated divergence.    |
| Reveries            | "The reverie loaded at session-start no longer matches my current sense". The load itself is the re-read. |

The _trigger's pattern_ (event-based, in-session, cheap) should trigger an **immediate** review of specific parts of the
content.<br/>
_Scheduled_ reviews are still important and should be user-initiated and periodic, but only **complementary** to the
pattern. These are meant to stale content that triggers can't catch.

### Alternatives considered

#### Unified tier with shape tags

> [!note]
> Rejected for now.

Instead of separate tiers, have a single Claude-writable tier with a `shape:` tag per entry (`shape: fact`,
`shape: impression`, `shape: pattern`) and let routing logic key on the tag rather than the file.

Possible advantages:

- Simpler mental model (one place to write, one place to read).
- No routing decision per insight ("global vs. project", "memory vs. reverie").
- Shape conventions enforced by tag rather than by file convention.

Separate tiers still win for the following reasons:

- The [five-axis differences][Deciding where memory goes] (loading, scope, curation, decay, privacy) aren't superficial.
  Reveries are absorbed as atmosphere with no query; memories are queried by topic; KB is grep-loaded on demand. Same
  epistemic difference, but each with its own, different mechanical needs.
- Format conventions encode register. Auto-memory's _Why:_ / _How to apply:_ structure crowds out narrative texture by
  design; reveries' "evoke, don't contain" rule excludes prescriptive content. Collapsing tiers loses that discipline.
- Per-tier visual separation makes auditing easier ("read just the reveries" vs. "filter by shape across thousands of
  entries").

This alternative is workable, not obviously wrong. If at some future point the cost of maintaining separate tiers
exceeds the cost of one unified tier with shape-tags, this is the design to revisit.

#### Offload writing to a dedicated `memory-contributor` subagent

> [!note]
> Rejected for now.

One would think a `memory-contributor` subagent could be dispatched from any session to file entries into
`~/.claude/memory/` or `~/.claude/projects/<project>/memory/`, the same way the `kb-contributor` agent handles writes to
the KB cross-project.

The advantages are the same as the KB contributor:

- The caller composes the content, the agent handles the plumbing (write topic file, append index entry, eventual lint).
- Cross-project writes feel symmetric with the KB flow.

The economics of the agent, though, do **not** work out:

- Filing a memory entry takes _two_ steps (write the topic file, append one line to the index), while its KB equivalent
  involves seven or more (write page, update `index.md`, check tags in `_tags.md`, add bidirectional cross-references,
  run lint, commit with the right attribution, push).<br/>
  Nearly all the work in memory filing is _deciding what to save and how to phrase it_, which the caller does regardless
  of whether a subagent exists. The mechanical overhead is just too low to justify the agent.
- The memory format is still evolving (new frontmatter fields, linking conventions, routing rules). Adding a tool
  requires codifying the current format, and forces an update with every evolution. With raw writes, the caller
  adapts immediately.
- The KB lives in its own git repository accessed from any project, which introduces the need for directory flags
  (`git -C`), absolute paths, and sandbox considerations a subagent can handle uniformly. Memory directories need to be
  **always** writable from **any** session, and are subject only to sandbox `allowWrite` rules. The mechanical
  complexity that justified `kb-contributor` simply does not exist.

Revisit this only if memory filing accumulates real mechanical complexity (lint checks, duplicate detection,
cross-memory linking, format validation).

## Further readings

- [Claude Code]
- [AI agents]
- [Manage Claude's memory]
- [karpathy/llm-wiki.md]
- [thedotmack/claude-mem]

### Sources

- [Documentation / Memory]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Deciding where memory goes]: #deciding-where-memory-goes

<!-- Knowledge base -->
[AI agents / memory tiers]: ../../agents.md#memory-tiers
[AI agents]: ../../agents.md
[Claude Code / auto memory]: ../claude%20code.md#auto-memory
[Claude Code]: ../claude%20code.md

<!-- Upstream -->
[Documentation / Memory]: https://code.claude.com/docs/en/memory
[Manage Claude's memory]: https://code.claude.com/docs/en/memory

<!-- Others -->
[karpathy/llm-wiki.md]: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
[thedotmack/claude-mem]: https://github.com/thedotmack/claude-mem
