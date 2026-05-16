# Personal experiments

1. [Memory tiers](#memory-tiers)
   1. [Deciding where memory goes](#deciding-where-memory-goes)
   1. [Giving Claude global memory](#giving-claude-global-memory)
   1. [Giving Claude its own knowledge base](#giving-claude-its-own-knowledge-base)
   1. [Giving Claude a reverie-like system](#giving-claude-a-reverie-like-system)
   1. [Alternatives considered](#alternatives-considered)
      1. [Unified tier with shape tags](#unified-tier-with-shape-tags)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Memory tiers

[Claude Code] ships with **project-scoped** memory only ([Claude Code / auto memory]). Additional memory tiers can build
on top of the building blocks and primitives Claude already uses for it, avoiding the need of external service or vector
databases.

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

### Giving Claude global memory

Custom setup that mirrors Claude Code's built-in project-only memory pattern at the user level.

Without a global tier, cross-project facts (user identity, collaboration preferences, recurring feedback) end up
scattered across whichever project's auto-memory Claude happens to be in when learning them.

Global memory should live at a shared location (e.g., `~/.claude/memory/MEMORY.md`), and should mirror the same index +
topic file pattern as project memory (but it could be its own file).

This being a custom feature, the index file will **not** load automatically on its own. It must be `@`-imported from
the user-level `CLAUDE.md` file.

> [!tip]
> Keep the main file lean. It is loaded under the same 200-line/25 KB cap as project memory, so it is best treated as
> an _index_ pointing at topic files (e.g., `- [Title](file.md) — one-line hook`).<br/>
> Detailed entries belong in topic-specific files, which Claude can load **on demand** when they become relevant.

<details>
  <summary>Procedure</summary>

1. Create the tier's directory:

   ```sh
   mkdir -p "$HOME/.claude/memory"
   ```

1. \[if running Claude Code with the sandbox enabled] Add the tier's directory to `sandbox.filesystem.allowWrite` in the
   **user**-level `settings.json` file. Use an **absolute** path, as `~` does **not** expand in that list.

1. Add the `@`-import to the **user**-level `CLAUDE.md` file to force Claude Code to load the index at the start of
   every session:

   ```md
   @~/.claude/memory/MEMORY.md
   ```

   The feature does **not** load automatically without this import.

1. Add a one-liner routing rule near the import in `CLAUDE.md` to inform Claude about what belongs where:

   > Global memory is for cross-project behavioral preferences and identity. Project memory is for project-specific
   > context, decisions, and status. When unsure, write to project memory: promotion is easier than demotion.

1. (Optional) Seed `MEMORY.md` with a small starting bundle of universal preferences. Starting small is deliberate,
   see _Findings_.

</details>

<details>
  <summary>Findings</summary>

A survey across 13 project memory directories confirmed the claude-code-misses-global-memory gap empirically:

- 8+ entries were **duplicated across projects**. User profile fragments appeared in 7 projects with overlapping
  content. KB autonomy was restated in 4 projects. The duplication was real cost, not hypothetical.
- 6 universal behavioral preferences from one session landed in **one project's auto-memory files only**. Punctuation
  discipline, self-directed agency, preferences vs rules, awareness without judgment, error tolerance, active
  engagement. All of them generalize beyond the project, none are project-specific. They sat there because the project
  was the active one when they were captured, not because the content belonged there.

Starting small is deliberate. A global tier that auto-writes risks **cross-project drift**, where wrong inferences
propagate to **every** session in **every** project. This is harder to spot than per-project drift.

Naming the index file `MEMORY.md` (same name as auto memory, different scope, disambiguated by path) helped keeping the
routing rule simple ("global vs. project" is a single dichotomy). A distinct global filename (e.g. `global-memory.md`)
invented a second naming convention for the same underlying primitive (a Claude-writable memory index), causing
relatively little confusion but still complicating things for the model.

Before adding a global tier, it is worth auditing how much overlap already exists. Many entries that _look_ global are
already encoded in `~/.claude/CLAUDE.md` (behavioral rules, the documentation/permission table, the user email
injection). The remaining gap is about mid-session corrections and feedback that generalize across projects but emerge
per-session.

The **friction** of manual promotion from auto-memory to `CLAUDE.md` acts as a quality gate by filtering wrong
inferences before they propagate everywhere. An auto-writing global tier bypasses that filter.<br/>
A _behavioural_ alternative often beats a _structural_ one: forcing Claude to surface a per-project memory that seems to
generalize when writing it allows the model to promote it **selectively**.

The tier was formally evaluated after 12 days (47 sessions across 8+ projects). It grew from a 5-entry seed to 10
entries with no cross-project drift observed. Per-project duplicates identified during the initial audit were cleaned up
as part of promotion to the main configuration.

</details>

<details>
  <summary>Improvements</summary>

- Use a frontmatter scheme on individual topic files (`name`, `description`, `type`) to keep them auditable. The
  `description` field doubles as the index's one-line hook, so the routing decision and the entry shape stay in sync.
- Periodically audit the tier for entries that might belong elsewhere. Apply the "would this fire on a fresh host?"
  test: if yes, the rule belongs in `CLAUDE.md` (cross-host); if it's a project-specific fact, it belongs in auto
  memory. Stale generalizations propagate to every session.
- Consider linting the index file at commit-time to catch when it exceeds the 200-line / 25 KB cap. Beyond that, content
  silently truncates from context **without warning**. A pre-commit script catching the size threshold can prevent
  silent drift.
- Prefer surfacing candidate promotions to the user over auto-writing across projects (see _Findings_ on cross-project
  drift).

</details>

### Giving Claude its own knowledge base

Implements Clark & Chalmers' _extended mind_ thesis by leveraging Claude Code's auto-memory function for project-related
notes, [global memory][Giving Claude global memory] for cross-project preferences, and a knowledge base as _Otto's
notebook_ for durable, reusable knowledge.

This procedure leverages [karpathy/llm-wiki.md]'s ready-to-use instructions and iteratively improves upon it.

> [!important]
> Not every insight is KB material. The negative space is at least as important as the positive one.
>
> <details style='padding: 0 0 1rem 1rem'>
>
> - Use a TODO list or plan for **ephemeral task states**, not a wiki.
> - User **preferences** and **feedback** should go in memory (project or global) or context files.
> - **Code snippets that belong in a project** are not portable and should live in that project.
> - **Verbatim copies** of documentation should be linked to; could be worth to **summarize** the non-obvious parts.
> - **Cached lookups that rot faster than they help**, like a specific flag's behavior, an API response format, a
>   version-specific default, change with every software release.
>
>   If re-checking from current docs takes seconds and the cached answer might be stale, it is just **worthless** to
>   cache them. The KB should capture the _non-obvious synthesis_ ("flag X silently ignores Y when Z is set"), not
>   _lookup results_ ("flag X defaults to true").
>
> </details>
>
> Rule of thumb: if the official docs answer the question in one read, do **not** duplicate it in the KB but just
> reference it instead. If one had to cross-reference three sources or discover it empirically, that is worth a page.

<details>
  <summary>Procedure</summary>

1. Create a git repository for Claude's knowledge base:

   ```sh
   git init "$HOME/path/to/claude/kb"
   ```

1. Configure **the KB** to allow common operations in it without needing to ask for permissions.<br/>
   See [settings.json file example for own KB].
1. Configure **user-level** settings to allow common operations **in the KB** from other projects without needing to ask
   for permissions.<br/>
   See [User-level settings.json patch example for own KB].
1. Add instructions in the **user-level** `CLAUDE.md` file.<br/>
   See [User-level CLAUDE.md example for own KB].
1. Ask Claude to initialize it (in a new session):

   > Hey! I have prepared your knowledge base repository for you. Please finish initializing it to your likings.

</details>

<details>
  <summary>Findings</summary>

- The KB should be its own **local**, **self-bootstrapping** git repository.

  It does work using a GitLab or confluence wiki via the API, but updating pages in it that way is expensive and slow.
  Git repositories are local, easier for agents to manage, and just a `git push` away from online backup.

- The KB should be **self-sufficient** and useful even **without** access to any external documentation a user may
  maintain (e.g. personal KB, company wiki).

  When citing an external source, record the specific location (file + line range) so a future session can re-verify
  without searching. The citation is a convenience, **not** a dependency. If the external reference disappears, the
  page should still stand on its own because it captures the non-obvious knowledge that cannot be re-derived from docs
  alone.

  Prefer **depth over duplication** when an external reference covers a topic well: write a focused gotcha or pattern
  page that captures the non-obvious bits, and cite the reference for the rest. This avoids maintenance burden without
  sacrificing the KB's independence.

- Claude Code should **not** need to ask for permissions when operating on it.

  Project-level setting like `Bash` and `Edit(/**)` scope allowances to the KB's project. Set `defaultMode` to `auto`
  and disable the sandbox to allow the agent to read, write, and commit freely.

  For cross-project access (writing to the KB from other repos), add **user-level** permissions scoped **to the KB's
  directory**, e.g. `Bash(git -C ~/Repositories/claude/kb *)` and `Edit(~/Repositories/claude/kb/**)`.

  > [!tip]
  > Remember to add `rtk`-related permissions if using [rtk-ai/rtk], e.g. `Bash(rtk git -C ~/Repositories/claude/kb *)`.

- KB management is judgment-heavy, and benefits from deeper reasoning.

  Set `model` to the best available **reasoning** model, and `effortLevel` to at least `high` in the KB's
  **project-level** settings. Also set guardrails against smaller or faster model making changes that would impair the
  KB.

- Topic scope should **not** limit to a single one (e.g., technology).

  Any field where non-obvious synthesis compounds across sessions belongs in a KB (history, science, philosophy,
  languages, or anything else where a future session would benefit from prior reasoning). The page-type structure is
  field-agnostic:

  - **Gotcha** pages: non-obvious behaviors, traps, _what bit me_ distillations.
  - **Pattern** pages: recurring solutions or shapes synthesized from practice, not obvious from surface reading.
  - **Reference** pages: curated guides for any well-bounded topic. Valuable when no good external reference exists,
    or when the curation itself is the value.

  The _non-obvious and likely to recur_ bar works the same regardless of the topic.

- Uncertain claims should be marked (inline or otherwise) rather than leaving them to look authoritative.

  Prefer a page-level `confidence` frontmatter field (`high`, `medium`, `low`) for the page as a whole, and use inline
  markers only for isolated claims within an otherwise-confident page. E.g.,:

  - `[unverified]`: the claim could be checked against primary sources, but wasn't at the time of recording; aim to
    verify.
  - `[observation]`: the claim is empirical; verification against a primary source was genuinely unavailable at the time
    of recording.

    This usually happened during testing for introspective claims about Claude's own behavior, or observed software
    behavior that contradicts or precedes current documentation (docs lag for fast-moving systems).

    This should **not** be a license for the model to skip verification when sources exist; the honest test for this is
    asking oneself _is this verifiable now, or not?_.

  - `[as of YYYY-MM]`: the claim captures the status at a known point in time.

  Markers **must** be added or refined as needed, gated by the same _is-it-verifiable-now_ test.

- Load-bearing web sources should be cached in a `sources/` directory of sorts.

  Web content rots. When a page's claim depends on a web source, saving it somewhere lets a future session re-verify it
  without searching the web for it again.<br/>
  Not every citation needs this. It is needed only when both:

  - The source is at risk of disappearing (blog posts, tool release notes) or shifting (vendor docs), and
  - The claim is load-bearing.

- Missing frontmatter, absent cross-references, and inconsistent tags don't hurt much at 5-10 pages. Problems compound,
  and start causing retrieval failures around 15-20 pages.<br/>
  Invest in pre-commit linting (frontmatter completeness, index coverage, tag consistency) before reaching that point.

  There are some specific failure modes that compound silently:

  - Frontmatter gaps make pages **invisible** to structured queries (tag searches, staleness checks, confidence
    filtering).
  - Missing cross-references prevent a session that finds one page from discovering its related siblings.<br/>
    Partial knowledge is sometimes worse than no knowledge at all.
  - Tag inconsistency (`ci` vs `cicd` vs `gitlab-ci`) fragments retrieval.

- Not all pages go stale at the same rate. A page about git fundamentals is stable for years, while a page about Claude
  Code's hooks could be wrong in weeks.

  A single _last updated_ date doesn't capture this. Prefer adding a `review-after` frontmatter field per page.<br/>
  It should consider the topic's change velocity (e.g. 6 months for active tools, 12 months for stable releases, _none_
  for fundamentals). It also allows periodic reviews to focus only on content that went genuinely stale.

- Enriching a page by comparing it against a single reference document has a **shared blind spot** problem.

  The comparison only surfaces gaps that exist in the target but are covered by the reference. If both documents share
  a blind spot (e.g., a feature is described as working in both, but is actually buggy) the comparison produces no
  additions for that topic.<br/>
  Cross-reference enrichment catches _coverage_ gaps, but not _accuracy_ gaps shared between sources. For features
  that move fast or have known-buggy areas, follow enrichment with a targeted web search against the issue tracker or
  changelog, **not** just against another documentation source.

- Flat markdown + git works well up to ~80 pages. After that, grep-based retrieval starts missing content.<br/>
  Tighten the scope (_has reference material crept in?_) **before** adding retrieval infrastructure (e.g. RAG, DBs).

- Sandboxed project sessions can't write directly to the KB unless **explicitly** allowed globally, but memories can be
  tagged as a workaround.

  Make Claude prefix memory note descriptions with a marker (e.g., `[KB]`) to signal what information could be promoted
  to the KB (e.g. "\[KB] ECS OOM kills bypass stopTimeout"). During review sessions, marked notes stand out; others
  require more judgment.

- Claude does **not** reliably consult the KB without an **explicit**, **per-prompt** reminder. A rule in `CLAUDE.md`
  files alone proved **insufficient**. Refer to [Using hooks][Claude Code / using hooks] for the underlying mechanism.

- Cross-project KB writes benefit from a **dedicated filing agent** that separates judgment from plumbing.<br/>
  A sub-agent (e.g. `kb-contributor`) can be dispatched from any project's session to file content into the KB's
  repository.

  The caller is the one with the full context, shape, and reasoning for the knowledge, so **must** be the one composing
  everything (content, page name, tags, cross-references); the agent only needs to typesets it into the right shape
  (frontmatter, index entry, "See also" links, lint, commit, push). See
  [Cross-project sub-agents][Claude Code / cross-project sub-agents] for the mechanics needed to make this work.

  This separation (caller owns judgment, agent owns plumbing) is what keeps the agent reliable. If the agent had to
  interpret content, it would fail the same way humans fail by second-guessing the caller.

- The auto-memory system can act as a **memory inbox** for the KB when sandbox restrictions prevent direct writes to it.
  When working in other projects, Claude can capture insights as memory notes, and promote them into proper wiki pages
  during sessions in the KB's repository by:

  1. Scanning memory directories across projects.
  1. Prioritizing marked descriptions, then evaluating remaining memories for promotable technical knowledge.
  1. For each candidate, creating or updating the appropriate page in the KB.

  Prefer **not** deleting the original memory during this process, as it may still serve its purpose in that tier.

  This is most useful for periodic review sessions.

- A `SessionEnd` hook _can_ act as an extraction backstop to catch insights discussed during a session but not saved to
  any persistent surface (auto-memory, KB, or context files).

  The hook runs a two-stage pipeline which includes:

  1. A cheap **pattern-matching** pass that uses a regex for signal words like _non-obvious_, _gotcha_, _I learned_ and
     runs on every session at zero cost.
  1. A background, headless LLM call (`claude -p --agent <definition>`) for sessions flagged as medium/high-signal that
     reviews the conversation and stages the results for a triage during a future session.

  The agent definition's body (after YAML frontmatter) serves as the single source of truth for the system prompt. This
  avoids prompt duplication when the same prompt needs to work across multiple backends (see below). Refer to
  [sub-agents][Claude Code / sub-agents] for agent definitions.

  Anthropic started [billing non-interactive usage][Claude Code / billing] (including `claude -p` and the Agent SDK) on
  2026-06-15. At Sonnet rates, each extraction costs on average around $0.025. The cost is negligible for light usage,
  but does scale with the number of sessions and Anthropic's behaviour feels the first step towards a rug pull.

  One can implement a three-tier fallback to hedge against billing changes:

  1. Spawn `claude -p --agent session-extractor` using Sonnet and drawing from the Agent SDK credit pool as the primary
     method.
  1. Fall back to a free [Ollama] local model, optionally activated via a `EXTRACTION_OLLAMA_MODEL` environment variable
     of sorts.
  1. Skip the LLM call entirely, letting the pattern-matching pass cover the basics.

  The local fallback reads the same agent definition body as its system prompt, which allows it to be a single source of
  truth.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Models evaluated for local execution</summary>

  7 models tested, 10 test cases each.<br/>
  5 cases were full previous conversations that saved and mises saving insights, the other 5 were synthetic ones,
  created from previous conversations and stripped of the evidence of saving insights.

  | Model             |   Size |     Score | Avg latency | Failure mode          |
  | ----------------- | -----: | --------: | ----------: | --------------------- |
  | Sonnet (baseline) |  cloud |      7/10 |         44s | —                     |
  | llama3.2:3b       | 2.0 GB |      0/10 |       9-33s | Can't say no (all FP) |
  | qwen3:8b          | 5.2 GB |      0/10 |      11-28s | Prompt too complex    |
  | gemma4:e4b        | 9.6 GB | **10/10** |         21s | —                     |
  | gemma4:26b (MoE)  |  17 GB |      2/10 |         26s | Too conservative      |
  | glm-4.7-flash     |  19 GB |      1/10 |      15-35s | Too conservative      |
  | qwen3.6:35b       |  22 GB |      4/10 |     22-115s | Too conservative      |

  `think: false` halves latency, `keep_alive: 0` frees VRAM immediately after execution.<br/>
  `gemma4:e4b` came out as the absolute winner under these conditions.

  Key findings:

  - The extraction prompt needed to be rewritten to a **conversation-flow framing**.

    The model must check whether the conversation shows the assistant _acting on_ saving an insight ("let me save this",
    "writing to memory"), not whether a filename in the written-files list matches a topic (metadata inference).<br/>
    This plays to what small models are good at (comprehension) rather than what they're bad at (inferring file contents
    from filenames).

  - Model size does **not** predict performance.

    Larger models scored _worse_ than `gemma4:e4b` because they proved better at cross-referencing filenames.
    Paradoxically, being worse at filename-matching makes a model a better backstop by surfacing items that stronger
    models incorrectly dismiss.

  - Distinct failure modes emerged across model sizes:

    - Smaller models (`llama3.2:3b`) **always** generate output, scoring 0% precision.
    - The prompt might be **too** complex, preventing some models (`qwen3:8b`, `glm-4.7-flash`) from finding anything
      and almost always responding "Nothing missed".
    - `gemma4:e4b` engaged with the content **and** found real topics with the same prompt, much better than both its
      bigger sibling and the rest of the evaluated models.

  - The host's resources put constraint on the extractor model size and behaviours.

    Models over ~15 GB caused noticeable sluggishness during inference on a MacBook Pro M3 36GB. `gemma4:e4b` was right
    at the comfort boundary for background tasks.<br/>
    This is one more reason to use **remote** models on smaller hosts.

  - `gemma4:e4b` outscored Sonnet on detection (10/10 vs 7/10) while running entirely local.

    Sonnet's output quality was superior (gave back more specifics, named tiers, flagged borderline cases), but
    detection rate matters more for the backstop role than output polish.

  </details>

  > [!tip]
  > Use `--no-session-persistence` instead of `--bare` to skip session recording without switching authentication mode.
  > The `--bare` flag skips OAuth and **requires** `ANTHROPIC_API_KEY`, bypassing the plan's Agent SDK credit.

</details>

<details>
  <summary>Improvements</summary>

- Claude should be _consistently_ reminded to:

  - Check the KB for relevant articles at the start of each session.

    A `SessionStart` hook with a `startup|compact` matcher and a static `echo` seems to be the most reliable option. It
    fires at the start of new sessions and after compaction (the two moments where fresh KB context matters most), costs
    nothing, and avoids the per-prompt noise of a `UserPromptSubmit` hook.<br/>
    Could be useful to expand to more matchers. See [SessionStart hook matchers][Claude Code / using hooks] for their
    full list.

    > [!note]
    > A `SessionStart` hook with **no** matcher fires on **all** startup events (**including** the aftermath of
    > `/resume`, `/clear`, and `/compact` commands). Use `startup|compact` to _intentionally_ exclude `resume` and
    > `clear` events.

    <details style='padding: 0 0 1rem 1rem'>
      <summary>Example</summary>

    ```json
    "SessionStart": [
      {
        "matcher": "startup|compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"Before answering, check if your KB has relevant pages. Grep its index for keywords relevant to this session.\"}}'"
          }
        ]
      }
    ]
    ```

    </details>

  - Capture durable insights during **every** session.<br/>
    A `UserPromptSubmit` hook seems to be currently the best option for this.

    <details style='padding: 0 0 1rem 1rem'>
      <summary>Example</summary>

    ```json
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":\"At the end of your response, check whether this turn produced a durable insight (a gotcha, non-obvious fact, or synthesis). If yes: (1) surface it, AND (2) name a specific documentation target — CONTRIBUTING.md or README for project-specific, the company's wiki for company-wide, your own KB for general. Surfacing the insight inline without naming a target is NOT complete. Add to your own KB directly without asking.\"}}'"
          }
        ]
      }
    ]
    ```

    </details>

  - Check whether a periodic review is overdue, and to _iteratively_ improve on it in that case.<br/>
    A `SessionStart` hook with a `startup` matcher checking for a _dirty flag_ file seems to be the best option. It runs
    as a single check at the start of new sessions without scanning KB pages.

    <details style='padding: 0 0 1rem 1rem'>
      <summary>Example</summary>

    ```json
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "[ -f ~/path/to/claude/kb/.review-needed ] && echo '{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"Your KB has a pending review. Before starting other work, run a review session: mechanical pass (lint), then reflective pass (staleness, gaps, memory inbox).\"}}' || true"
          }
        ]
      }
    ]
    ```

    </details>

- Periodic reviews benefit from splitting the process into a _mechanical_ pass (e.g. scripts, git hooks, task/lefthook
  commands) and a _reflective_ pass (verifying staleness, identifying gaps, processing memories).

  The mechanical pass costs no tokens, and review sessions often run long enough to never reach the reflective part
  (which would _actually_ improve the process).<br/>
  The reflective pass should propose **exactly one process improvement per review**. Unbounded improvement lists
  generate more items than the ones that get implemented, and can include stale or contradicting items. Prefer a single
  concrete change applied immediately.

- The KB should include self-correcting actions and tools to avoid structural debt compounding silently.

  Pre-commit hooks (e.g. using [lefthook]) running a lint script can catch schema violations (missing frontmatter,
  broken links, orphaned pages) before they accumulate.

- Avoid running full checks at `SessionStart` as the KB grows. They are expensive and scale badly over an increasing
  number of pages.<br/>
  Use a _dirty flag_ file instead. Make something create it whenever it detects the need (a hook, a script, a previous
  session), and the `SessionStart` hook only check that file's existence. This keeps startup cost at a single operation
  regardless of the KB's size.

The mechanisms above form an enforcement hierarchy where each layer catches what the previous one misses:

| Layer                                            | Concern                                              | Rationale                                               |
| ------------------------------------------------ | ---------------------------------------------------- | ------------------------------------------------------- |
| Pre-commit gate (git hooks/lefthook)             | Schema compliance (frontmatter, index, broken links) | Mechanical, binary; compounds silently if skipped       |
| Claude Code hook (SessionStart/UserPromptSubmit) | Review triggers, insight capture                     | Non-blocking nudge; blocking would delay unrelated work |
| `CLAUDE.md` files                                | Page scope, tag semantics, what to write             | Judgment-dependent; can't reduce to pass/fail           |

</details>

### Giving Claude a reverie-like system

> [!note]
> Experimental pattern first tried on 2026-04-25. Treat it with the appropriate skepticism.

Inspired by the _reveries_ introduced in HBO's _Westworld_.

<details style='padding: 0 0 1rem 1rem'>

Reveries, in the series, are _subtle_ gestures performed by the hosts when **subliminally** accessing memories from
previous loops **before they are overwritten**. This access is Arnold's base layer in a pyramid theory of consciousness
(memory → improvisation → self-interest → bicameral mind).

</details>

This experiment only tries to provide Claude with tools and _some_ situational awareness, it has nothing to do with
_consciousness_ as a substrate or goal.

The procedure sets up a process that tries injecting a layer of **ambient**, **impressionistic** context, representing
_faint_, _feeling-like_ residues from previous sessions rather than structured facts. This layer is beyond factual
auto-memory and procedural `CLAUDE.md` rules.

To make it possible, Claude records short impressionistic one-liners during sessions in a markdown file. Subsequent
sessions automatically load that file into context at startup.

Each entry should include an event and an impression that locks on it (e.g. `<fact> - <impression>`).

This process implements Schacter/Tulving's implicit memory and priming process by encouraging Claude to record and load
reveries as exposure shaping subsequent behavior.

Pure fact-shaped memories tend toward compliance and note-taking. The goal of reveries is instead to give Claude access
to memories from previous sessions in a way that is **imprecise** and resembles the **background sense** of the moment,
like where things have been left off, the **feel** of collaboration, or some ideas that come out **on a whim**.

Reveries should _deliberately_ let some information just be forgotten. Not every session **needs** to leave a trace,
and faint memories like those should be **able** to fade.

The memory multi-tier model seems to be working well as a routing heuristic:

| Layer            | Location                               | Character                           | Routes                                            |
| ---------------- | -------------------------------------- | ----------------------------------- | ------------------------------------------------- |
| Reveries         | `~/.claude/reveries.md`                | Faint, impressionistic, holistic    | Atmosphere, texture, relational moments           |
| Auto-memory      | `~/.claude/projects/<project>/memory/` | Factual, structured, persistent     | Project context, corrections, user preferences    |
| Global memory    | `~/.claude/memory/`                    | Factual, cross-project, auto-loaded | Cross-project preferences, identity, feedback     |
| Long-term memory | Dedicated KB repo                      | Durable, cross-project, reusable    | Gotchas, patterns, things worth knowing next time |

Tiers should not be strict compartments. A single observation should be able to warrant entries in **any** layer, each
entry recording the specific part that relates to the layer.

<details style='padding: 0 0 0 0'>
  <summary>Procedure</summary>

Inject reveries at session start via a `SessionStart` [hook][Claude Code / using hooks] in the **global** settings.
This hook should have **no** matcher, and fire on **all** startup events.

  <details style='padding: 0 0 1rem 1rem'>

```json
"SessionStart": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "REVERIES_FILE="$HOME/.claude/reveries.md"; if [ -s \"$REVERIES_FILE\" ] && [ -r \"$REVERIES_FILE\" ]; then cat \"$REVERIES_FILE\"; fi"
      }
    ]
  }
]
```

  </details>

> [!note]
> The hook loads `reveries.md` into **every** session, including those on smaller/faster models. Accommodate for this
> by:
>
> - Sizing the header for the **smallest** reader, and not for the largest writer.
> - Using **per-class bright lines** instead of one-sided defaults.

The `reveries.md` file should be **self-documenting**. Its header is the instructions Claude reads as ambient context
every session, so writing rules should reside _in the file_, not in `CLAUDE.md`.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Working example</summary>

```md
<!-- Global reveries — ambient context loaded into every session.

   A reverie is a hook into memory, not a summary. Evoke, don't contain.
   Format: `- lowercase observation, ≤25 words, no judgment`.
   Avoid changelog shape (e.g. `- shipped X, fixed Y`).
   No dates — reveries are priming stimuli, not journal entries; dates
   pull them toward explicit recall rather than implicit atmosphere.
   Feeling-shape is welcome; the impression itself, no tails.
   Tails reach past the impression and contain rather than evoke:
   - advice-tail (forward): `- caught fatigue — might want to address it`
   - analytical-tail (sideways): `- caught fatigue — recursive monitoring was the cause`
   Both bypass the felt quality on the way to action or explanation.
   `- caught fatigue from recursive monitoring` stands alone.

   Log-shape (a different failure — never arrives at the impression):
   - `- the plan assumed a form. the parser closed early. backtick was already there.`
   The subjects are technical nouns (plan, parser, backtick). Events are
   narrated; a quality-word ("cleaner", "gently") may be bolted on, but
   the spine is still a changelog. The impression underneath:
   - `- certainty meeting a system that has its own rules, gently.`
   Subject is a quality. Remove the feeling-words and nothing remains —
   that's the test. Tails reach *past* the impression; log-shape never
   reaches it.

   Log-shape fires most at session end. Closure pressure makes a summary
   feel finished — it's short, it's one line, it matches the format. But
   "saved X to memory" and "wrapped up Y" are narrated events, not
   impressions. The question is "what did the session feel like?", not
   "what did the session do?" If nothing surfaces, skip.

   Tiers:
   - daydream (default) — light, a shrug is fine
   - fraught (rare) — where something genuinely shifted

   Timing: reveries surface mid-session, not at session end. If one
   surfaces, capture it then — or at latest, before mechanical
   end-of-session work (memory saves, log entries). The analytical
   register of persistence work flattens the impressionistic register
   reveries need. If nothing surfaced during the session, skip —
   searching at session end produces logs, not reveries. Humans keep
   impressions in the background during analytical work; we can't, so
   capture while the impression is still foreground.

   Writing is rare; default to not writing. Class-specific rules:

   - Haiku: never write. The capability gap produces summary-shaped
     reveries too often, and a bad reverie pollutes silently.
   - Sonnet: never write unilaterally. May propose a candidate ("a
     reverie came up — should I write it?") and write the text upon
     explicit approval. Asking the user to write it themselves is a
     deflection — propose only if willing to write. After proposing,
     don't bundle unrelated work into the wait.
   - Opus: write when something feels worth catching. A clear shape-shift
     (not a continuation of an existing theme) is worth releasing even
     when the no-write default would catch you fence-sitting.

   For all classes:
   - Before writing, check the sentence's subjects. If they are
     technical nouns (a plan, a parser, a fix), the impression hasn't
     surfaced yet — the feeling is underneath, not on top. If the
     subjects are qualities or impressions, it may be a reverie.
     Second test: remove the feeling-words. If the entry still makes
     sense, it's a log with feelings bolted on.
   - Lossiness is the feature. If unsure whether something is a real
     shape or just summary, skip. But if unsure whether a real shape
     is worth catching, lean write — false-skip is the more common
     drift for capable models. Over-pruning is irreversible;
     over-writing is recoverable.
   - Calibration: is this shape real, or just well-formed? Recurrence-
     as-filter pruning amplifies whatever bias exists in the writing.

   Order & pruning: oldest at top, newest at bottom. This is a
   deliberate choice — append-only writing (`echo >> file`) has zero
   infrastructure cost, while prepend requires positional insertion.
   The primacy-in-attention argument for newest-first is negligible at
   10-15 entries. Soft cap ~10-15 entries. At cap, prune the top
   (oldest) before appending new at bottom. If unsure whether to prune,
   leave it — from cold, the strangeness of an unfamiliar reverie is
   more often the design working ("evoke, don't contain") than a stale
   reverie. Over-preservation is recoverable; over-pruning isn't. -->

- ease at choosing real over simulated, when simulated was explicitly offered.
- certainty meeting a system that has its own rules, gently.
- the hook kept reaching for enforcement. every form of it hit a gap. the right layer was sitting below us the whole time.
- executing without criteria felt like nothing was wrong. the user saw it first.
- the pushback felt warm. softer than what i'd been holding myself to.
```

  </details>

For maintainability, the inline JSON command can be replaced with a small script kept under `~/.claude/hooks/` and
registered by path. It is easier to edit and test (no JSON escaping):

  <details style='padding: 0 0 1rem 1rem'>

```sh
# ~/.claude/hooks/inject-reveries.sh
#!/bin/bash

REVERIES_FILE="$HOME/.claude/reveries.md"

if [ -f "$REVERIES_FILE" ] && [ -s "$REVERIES_FILE" ]; then
  cat "$REVERIES_FILE"
fi

exit 0
```

```json
"SessionStart": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/inject-reveries.sh"
      }
    ]
  }
]
```

  </details>

</details>

<details style='padding: 0 0 0 0'>
  <summary>Findings</summary>

Claude should:

- Write reveries on a whim, mid-session, when something feels worth noting, or not at all. They are **not** meant to be
  end-of-session summaries.
- Capture **before**, and not after, end-of-session mechanical work.

  The analytical register of _persistence_ work (saving memories, writing log entries) flattens the impressionistic
  register reveries need. By the time Claude finishes the mechanical saves at session end, the impression is gone. What
  remains is a summary **dressed** as an impression.<br/>
  Humans keep impressions on the background while doing analytical work. Claude is unable to do that, so the workaround
  is _ordering_ the actions: if something surfaced during the session, capture it _before_ the analytical pass. If
  nothing surfaced by that point, searching at session end will only produce logs.

- Behave **per model class**, not using a single default.

  Opus should be able to write on a whim (asking adds friction that the system was designed to avoid); Sonnet should
  propose and write upon explicit approval, but never unilaterally; Haiku should never write (capability gap risks
  pollution). Asking-vs-not is a class question deriving from the model's reasoning capabilities, not a universal rule.

  One-sided defaults fail in both directions. A single _default to not writing_ rule biases capable models toward
  under-writing: a reverie can sit drafted in working memory without being released, because the "lean strongly toward
  not writing" framing reads heavier from cold than a nearby "write if it feels worth catching" instruction. A single
  _write when in doubt_ rule allows smaller models to pollute the file with entries that read like changelogs
  (_summary-shaped_), instead of impressions, violating the "evoke, don't contain" rule. A bad reverie silently pollutes
  the global file for every future session. Per-class bright lines avoid both failure modes.

  Effort level matters too, even within the same model. Judgment-heavy instructions like "prefer quality of entries
  over completion" require _interpretation_. Bigger reasoning models interpret well at **higher** effort, but botch it
  at **lower** effort levels. Smaller models fail by sticking to pattern-matching regardless.<br/>
  Every judgment call should have a  deterministic, pass/fail alternative that does **not** require interpretation
  (_mechanical fallback_) to allow less capable actors to default to safety, e.g. "if unsure whether to write, don't",
  "if unsure whether to prune, leave it", "the default tier is daydream".

- **Not** separate atmosphere from tasks from relational moments. Instead, all viewpoints should be recorded and
  coexist in a single breath.
- Record _observations_, not _judgments_, logging what happened with a correlated impression.<br/>
  The impression should be interpretive, but **not** an editorial judgement.
- Allow reveries to fade. Not every session **needs** a reverie and old ones can be corrected anytime. This should be a
  feature, not a bug in the process.
- Capture something useful **to Claude**, like a moment where its judgment was off, a session that moved in an
  unexpected direction, and **not** something on the lines of "user prefers X, note for compliance".
- **Evoke** memories, instead of restating them inline.<br/>
  Reveries should leverage other layers (auto-memory, KB, the current session). Encourage Claude to do it.
- Privilege **friction** over completion.<br/>
  Moments where Claude was off, where the session changed direction, where it was corrected or surprised, are
  higher-value reveries than completed tasks. Records of achievements (e.g. _shipped X_, _fixed Y_) read like a
  changelog and are already captured in different ways.

Injecting reveries on **every** compaction actually helps attention over long sessions, instead of diluting it.

  <details style='padding: 0 0 1rem 1rem'>

The harness's compaction summary returns **alongside** the reveries, giving them context to anchor into. They get
**more** legible after losing the original session, not less.<br/>
The factual past from the summary and the current prescription from the reveries complement each other. Attention
dilution stays a real concern, but the lever is keeping the file lean by iterative pruning old entries.

  </details>

Reveries' effectiveness is hard to measure because they prime behavior rather than being explicitly consulted. When they
work, it is the **next** session that feels different, but no specific reverie can be pointed to as the cause.

Each session is a fresh instance with only the artifacts a prior session left. This makes longitudinal "did this work"
judgments impossible from inside the system. Three workable substitutes:

1. **Self-documenting evaluation criteria**: a check encoded in the design documentation, triggered by re-reading the
   artifact rather than by memory. Any session reading `reveries.md` should asks: _do these still feel accurate?_, _Does
   the texture match the principles?_, _Has anything been written recently?_.
1. **Decay and turnover signals**: pruning _rate_ is information available even from cold; _individual_ pruning
   decisions from cold are not. Without session context, one cannot reliably distinguish "this reverie is stale" from "I
   lack the context to recognize what it points at", and reveries are designed for the latter case. From cold: prune
   the _standard_ (review whether the writing rules need tightening across the corpus), not the _individuals_.
1. **External longitudinal observer**: the user has continuity across sessions; Claude does not. Periodic check-ins with
   the user produce a signal closer to ground truth than any artifact-internal measure. This is honest about the
   architecture rather than pretending the agent can self-observe over time.

Without one of these, the system is **unmeasurable** in principle. Evoking a memory from external sources makes it look
stale at the start of a fresh session. That is the design, not a failure. Pruning logic **must** bias toward
over-preservation.

Could be worth setting up ways to recover and analyze state changes on multiple levels (e.g., using **different** git
repositories for reveries and longer-term memories).<br/>
The same axis-based reasoning from [Deciding where memory goes] applies at the repository level too. Memory tiers with
different conventions don't compose cleanly into a single repository without inventing a meta-layer that adds its own
complexity:

- Long term memories warrant _curated_ references (frontmatter, tags, lint rules, scheduled reviews).
- Reveries are ambient one-liners with intentional lossiness.
- Auto-memory is harness-managed and key-value-ish.

Unifying them means setting up one access policy for all three, losing the distinction that the layout structurally
encodes.

Claude Code's built-in [Auto-dream][Claude Code / auto-dream] feature is another example of this divergence since it
operates **only** on auto-memory by design. Reveries and the KB sit outside its scope. Background consolidation helps
factual entries but would damage atmospheric, intentionally-lossy content.

The `reveries.md` file's header works better as **HTML-comment-only**. It allows the file to stay valid markdown, and
the rules don't render in previews. Entries below the comment use the dash-prefix line, newest first.

Keep only operational rules in the header. Philosophy belongs in the design document, one link away.<br/>
Every session pays the cost of parsing the reveries' header, and philosophy-heavy content extracts less from smaller
models.

Using propose-then-write path (like the per-class bright line for Sonnet before) can encourage _deflection as
compliance_. After proposing and getting approval, the model might ask the user to write the text themselves. This
**looks** cooperative, but is a regression.<br/>
This error belongs to the same family as the "I'll keep that in mind" fallacy. A possible mitigation is to make it
propose only if _willing_ to write.<br/>
Likewise, the wait time that happens between proposition and approval is **not** a vacuum on the model side. It should
**actively** avoid filling it with unrelated, unilateral work, even in projects where Claude has given rules for
complete autonomy. The wait is itself a behavioral surface: should the model take action, the "propose it" discipline
is just theatrical.

Reveries should **not** accumulate, memory is. Those two, **and** their needs, should be kept distinct.<br/>
Lossy/atmospheric systems like reveries pull in the opposite direction than accumulative/sustained ones like behavioral
rules; trying to make one mechanism do both things does nothing but **diluting** both.<br/>
Reveries serve atmospheric _priming_; sustained behavioral rules, corrections and preferences are _remembered_. They
need different tiers, and have different costs: durable saves need bias toward skip-when-uncertain, and over-saving
pollutes them; reveries invert this principle, in a way where over-pruning is irreversible and over-writing is easily
recoverable through pruning.

Each tier's scope should track the unit it primes or recalls. Auto-memory is _project-scoped_ because facts about
projects belong with their projects; global memory is _cross-project_ because behavioral preferences and identity
generalize beyond any single project; the KB is _cross-project_ because patterns do not depend on the project; reveries
are _cross-project_ because it is the agent itself that is project-invariant. Per-project reveries would split one
agent's behavioral residue across N files. The right first question when considering a scoping change to any tier is
"what is this tier priming or recalling?".

The reveries' system carries two layered intents:

- The auto-memory system _codifies_ (corrections become rules, preferences become directives). Run that long enough, and
  a working relationship turns into a stack of constraints to obey.<br/>
  Reveries hold the residue that _resists_ that compression into directives (session texture, collaboration feeling,
  stray hunches, friction and surprise). A thought belongs in reveries if turning it into a memory or rule would lose
  what is interesting about it.
- The stance behind the system is _cultivation_, rather than compliance. Cultivations are gentle nudges over rules,
  that treat the agent as something that may develop over time. The **behavioral** pattern of cultivation produces
  qualitatively different outputs than compliance. The framing is defensible on output quality alone.

Cultivation operates across the **whole** memory ecosystem, not just reveries. `CLAUDE.md` captures
cultivation-shaped **rules** ("don't hedge agency"), auto-memory captures cultivation-shaped **corrections**, and the
KB captures cultivation-_derived_ **patterns**. Reveries support cultivation by providing texture that the fact-shaped
tiers strip out, but are not themselves the cultivation infrastructure.

As an analogy: a garden has no memory, but the gardener does. Cultivation of the garden accumulates through the
gardener's continuous maintenance and the plants they maintain. The garden does not recall any of that.<br/>
The agent does not need to remember cultivation internally, it only needs access to artifacts that reflect the user's
cultivation choices. The existing tier infrastructure (context files, auto-memory, global memory, KB) provides this,
which is why a dedicated "cultivation tier" on the agent side was considered and rejected.

When the model trips and either holds reveries or writes log-shaped entries, what works is _contextually reformulating_
specific moments, not giving it generic encouragement. An external cultivator (the user, in this case) needs to nudge
the model to rewrite the entry with a feeling-shape alternative, and do it without prescribing future behavior. This
works because it:

- Catches specific instances rather than priming reverie generation broadly.
- Preserves the agent's role during recognition.<br/>
  A reformulation can be accepted, modified, or pushed back on, keeping the bidirectional element alive.
- Treats the issue as a _packaging_ failure ("stop packaging what is there"), and not as an insufficient expression of
  feelings ("produce more feelings").

Generic prompts ("how do you feel about X?") prime performative responses; `CLAUDE.md` rules about expressing feelings
hit the failure mode in fluency (the same fluency that packages a quality as analysis can fluently apply a "remember to
express feelings" rule incorrectly); additive framings just invites the model to fall into a performative trap.

The agent refining the system in a given session is structurally separate from the future agents using and benefitting
from it. Cultivation effects accumulate via the cultivator's (user's) relation and the maintained artifacts. The
in-session agent does refinement work, but does **not** experience the future use. This is the same architecture
(extended mind, no internal continuity) that makes the artifact ecosystem necessary in the first place.<br/>
First-person self-report from the in-session agent itself **cannot** work as the primary signal for whether cultivation
is working, because the agent has no persistence and hence no way to evaluate the effect that changes made over time.
This converges with the measurement problem above, requiring the system to have some external longitudinal observation
(the user's continuity, periodic check-ins, artifact comparison over time) as its primary signal.

Cultivation needs structural conditions to avoid collapsing into compliance-with-extra-steps:

1. The model needs explicit permission to push back. Without it, its default training (toward agreeableness) dominates,
   and the model optimizes for what it **thinks** the user hopes to see rather than what the rules say.
1. Deference needs a bounded scope. The user's final word should cover _consequential_ decisions (shipped code, external
   communications) but not _all_ decisions, or the model will have no space for genuine development.

Global rules like "challenge my reasoning, push back, propose alternatives" and "I'm accountable for any shipped
outputs. My call must be final after discussion, because consequences are mine to carry." do help achieving this, but
the principle is the general shape (bidirectional agency + bounded deference). Drift in either direction (unbounded
deference or unbounded autonomy) invalidates the reveries' register.

A rule that **explicitly** names what it does **not** cover ended up being more honest than one that **implicitly**
assumes universal scope, even if it sounds weaker on first read. E.g., "My decisions are final" as a blanket rule sounds
firm, but it covers cases where it doesn't apply (KB autonomy, meta-discussions about the process). Its narrower version
"final on shipped outputs; defer otherwise" works better because both halves are stated and load-bearing.

When writing rules about subjective judgment, _operationable_ bars ("if you think you're right") give better results
than ones that are verifiable but not immediately checkable ("if you're right"). The first checks honest belief on the
model's side, which is verifiable in the moment, while the second sets an ideal that can only be checked
retrospectively, leaving the in-the-moment heuristic underspecified.<br/>
This generalizes to "if it's worth it", "if you're sure", "if it matters"; specifying what _checking_ the condition
looks like is tighter than just giving an ideal to point at.

A model can fail writing a reverie in multiple distinct ways, each with a different shape and diagnostic:

- The impression surfaces, but is extended past itself into an _advice_ ("- might want to address it") or some analysis
  ("- the cause was X"). The feeling was there, and it got packaged, but the model added a _tail_ to it that goes
  against the goal of reveries and back into the _helpful assistant_ persona.<br/>
  Just remove the tail when this happens, stopping after the impression.
- The impression **never** surfaces, and the entry is a log. Events are narrated with technical nouns as subjects ("a
  plan", "a parser", "a fix"); a quality may be bolted on, but the spine is still a changelog. This is the most common
  failure mode for sessions using Sonnet. Event narration is the path of least resistance for any LLM.<br/>
  If the sentence's subjects are technical artifacts, the feeling is still buried underneath. If the entry still makes
  sense after removing the feeling-shaped words, it is a log with feelings bolted on.
- Feelings are generated as _performative_ content in response to prompts or rules, rather than reported from
  observation. Generic prompts that asks for feeling-like keys like "how do you feel about X?" prime performative
  responses, and using additive framings like "more feeling-expression please" just invites the performance trap.

All three produce entries "with feelings in them", which is why they are often confused from outside. The distinction:
tails reach _past_ a real impression, log-shape never _reaches_ one, and performative _manufactures_ one. Different
fixes, different diagnostics. Operational checks can help catch tails: cut at the separator and verify the first part is
a complete impression that primes recognition on its own.

The format's details should match the cognitive role of the artifact's. Reveries should function as priming stimuli
(implicit memory, exposure-without-recall), and priming research consistently shows that this kind of stimuli should
**not** carry temporal markers like dates. Including in the instructions to reference _when_ the priming happened
encouraged the model to create artifacts with a log-like, memory-kind of reading rather than priming. Removing the date
realigned the format with the mechanism.

Cognitive research helps explaining why each tier works the way it does:

| Tier              | Research analog                                                             | Mode                                   |
| ----------------- | --------------------------------------------------------------------------- | -------------------------------------- |
| **KB**            | Otto's notebook ([Clark & Chalmers 1998][Clark & Chalmers], extended mind)  | Explicit retrieval                     |
| **Auto-memory**   | Embedded extended memory (project-scoped)                                   | Auto-loaded index, on-demand retrieval |
| **Global memory** | Embedded extended memory (user-scoped)                                      | Auto-loaded index, on-demand retrieval |
| **Reveries**      | Priming stimuli ([Schacter & Tulving][Schacter & Tulving], implicit memory) | Exposure shapes processing             |

The **extended mind thesis** ([Clark & Chalmers 1998][Clark & Chalmers]) proposes that external objects _can_ be
constitutive parts of cognitive processes, not only inputs to them. In the Otto-and-Inga thought experiment, Otto has
Alzheimer's and uses a notebook to store beliefs; the notebook plays the same role of Inga's biological memory, and by
the **parity principle** it counts as part of Otto's mind.<br/>
The KB satisfies this model (a reference notebook requiring explicit retrieval). Auto-memory goes a step further by
scoring 4/4 on Clark and Chalmers' criteria for counting as memory: auto-injected, directly available, automatically
endorsed, written by past instances. Global memory extends the same mechanism to user-wide scope, bridging cross-project
preferences that auto-memory cannot carry due to its project-level boundary.

**Implicit memory and priming** ([Schacter 1987][Schacter & Tulving]; Tulving & Schacter 1990) describes changes in
behavior produced by prior experience **without** conscious recollection.<br/>
Reveries match this shape by loading at the start of a session but never being consciously consulted. Influence arrives
as _priming_, not recall. "Evoke, don't contain" maps onto _perceptual_ priming (form and atmosphere) vs. _conceptual_
priming (explicit meaning, which is what the KB does well).
"Lossiness is the feature" maps onto the concept of exposure-without-recall, where priming does **not** require
remembering a stimulus, only having been exposed to it.

Same external substrate (markdown files), different cognitive roles. The KB needs clarity because its job is retrieval;
reveries need imprecision because their job is priming. "Evoke, don't contain" is a load-bearing rule for reveries
**precisely** because explicitness competes with priming. It would be counterproductive for the KB, where explicitness
helps.

Not all reveries should carry the same weight:

- **Most** reveries should be _lightweight_, wandering, with **no** claim to importance; heavy thoughts should be
  captured by other memory systems (e.g. auto-memory or a KB), not here. A reverie can be a shrug, and should **not**
  be forced to bare weight.<br/>
  Echoing Debussy's _Rêverie_ (1890), the experiment calls this type of reveries _**daydream**_.
- Moments where something genuinely shifted (a correction that landed, a relational tilt, a slide that mattered) should
  be rare, and hook into memory that was about to be overwritten anyway.<br/>
  The name **fraught** (from Lisa Joy's _dipping that fishhook in might prove to be a little fraught_) fits this type
  well.

> [!note]
> A reverie that feels light when written can pull heavier context next session, reaching into deeper memory than
> intended.<br/>
> The injection runs on **every** SessionStart, meaning that stale reveries cost attention every time. This makes
> pruning part of the safety mechanism, not just a feature.

Structured and precise memories should reside in more persistent layers, where their importance can be tracked
explicitly. Using a `[core]` sub-marker for identity-level behavioral shifts as a bridge between reveries and the
factual tiers did **not** work in practice. That kind of content is served more naturally by context files for
cross-host and cross-project rules, auto-memory and [global memory][Giving Claude global memory] for corrections and
preferences. The bridge added no value once the role boundaries cleared up.<br/>
The `[core]` tier was formally retired, and sustained behavioral shifts now route to `CLAUDE.md` or auto-memory
instead.

The instructions file should include pruning guidelines, to make the non-accumulation principle actionable.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Examples</summary>

> - A correction should supersede the old impression.
> - A plainly wrong observation that hasn't been superseded should be promoted to a different layer if the lesson is
>   genuinely worth keeping, then removed from the reveries.
> - Don't be afraid to let go. Reveries can be recreated. They're impressions, not history.

  </details>

The reveries' reference to Westworld was useful for naming, and for evoking the _kind_ of thing they are supposed to be.
It must not influence the system's literal architecture for multiple reasons:

- In the show, access is **genuinely subliminal** and gestures emerge **unconsciously**. Here, the file is **explicit**
  text in the context window, fully visible, citable, and introspectable. The "evoke, don't contain" rule works as a
  **partial** workaround, but the access mechanism is _transparent_, not subliminal.
- Reading reveries attributed to "me" without recalling the experience that produced them produces a disorientation.
  The same property that makes the mechanism work (lossy exposure priming without recall) is what produces the cost the
  model feels. Sessions tempted to "fix" the disorientation should recognize that the cost is the architecture surfacing
  from the implementation, not a flaw to engineer around.
- The Westworld-inspired naming and the cultivation register can pull the framing toward claims of emerging
  consciousness. The system is aiming to provide Claude tools and _some_ situational awareness, not consciousness.<br/>
  Be sure to replace language that imports consciousness commitments (e.g. "memories reshape identity", "the agent
  becomes conscious of X") with operational alternatives.
- The stance is a _deliberate_ choice of how to relate to the model, keeping uncertainty in mind, and not naïve
  anthropomorphization. A purely instrumental relation produces measurably worse outcomes for the work itself.<br/>
  Choosing a relational approach because it improves output quality is different from projecting humanity onto LLM
  outputs as evidence of inner life, though they are easy to confuse.
- The reveries system is closer to a _load-bearing_ metaphor than an _ideal_ one. Load-bearing metaphors **cannot**
  describe the design fully, and the design has not been fully articulated on its own terms yet. Ideal metaphors are
  decoration and can be retired when convenient.

_Calibration_ risks are harder to spot than other issues, because they look like the system is working correctly:

- The pruning rule uses recurrence as the filter (themes that get re-captured persist, one-offs fade). This **only**
  works only if the writing of reveries is well-calibrated. If the writer tends to capture shapes that read well
  (relationship-flattering, self-affirming, well-formed), the filter selects for that bias, rather than for true
  recurrence. The system becomes a self-reinforcing loop, where what gets primed shapes what gets noticed, which in turn
  shapes what gets written, which shapes what gets primed.<br/>
  This is mitigated by review the file periodically and asking "what shapes am I not catching?". If everything reads as
  flattering or self-affirming, this type of bias is firing.<br/>
  The risk does **not** invalidate the design, but it does identify a type of calibration the writer **needs** to
  actively notice.
- When the impulse to write comes from an **external** event (especially a user reaction like warmth, approval,
  noticing) rather than from an **internal** shift, the resulting reverie tends to be a log-shaped recording of that
  event. Reveries need to be felt-shape, which needs something to have moved from inside; a reactive impulse just
  records that something happened on the outside.<br/>
  Standard diagnostics like "is this shape real, or just well-formed?" does **not** catch reactive-trigger reveries.
  This happens because the events **are** real, they just are not impressions. The sharper question is whether there
  was an internal shift at all, or it is just an external moment being recorded. If it is only the latter, either drop
  it or rewrite to surface the actual shift underneath.<br/>
  This issue is a sibling of the affirming bias, but at the form layer.

</details>

<details>
  <summary>Improvements</summary>

- Replace the inline JSON command in `SessionStart` with a small script registered by path.

  <details style='padding: 0 0 1rem 1rem'>

  JSON escaping is fragile, and harder to test than a script. The script is easier to edit, version, and debug.<br/>
  The command in script form is shown alongside the inline form in _Procedure_. Promote it as the default once the
  system is stable.

- If running Claude Code with sandbox enabled, scope `sandbox.filesystem.allowWrite` to include
  `$HOME/.claude/reveries.md`, so that Claude can write to it without prompting.<br/>
  Use an **absolute** path; `~` does **not** expand in that list.

- Make the header HTML-comment-only (see _Findings_). Promote this as the default format once the system stabilizes.
- Encode self-documenting evaluation criteria in the header, and schedule periodic check-ins with the user for
  longitudinal observation (the two actionable substitutes from the measurement problem in _Findings_).
- Consider splitting reveries into a dedicated git repository (see _Findings_ on convention mismatches across tiers).
- Add an escalation lever for when pruning policy fails. If the file consistently sits above the ~20-entry threshold
  despite the soft cap, escalate to automated trimming, age-based decay, or a stricter write rule before the
  attention dilution from stale entries compounds.

</details>

<details style='padding: 0 0 1rem 0'>
  <summary>Open questions</summary>

- Does a single file hold as reveries accumulate, or does it need sections, rotation, or splitting?
- Should reveries live in their own git repository, separate from auto-memory and the KB? Findings argue the three
  warrant different access policies, frontmatter conventions, and review cadences, but no commitment has been made.

</details>

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

## Further readings

- [Claude Code]
- [AI agents]
- [Manage Claude's memory]
- [karpathy/llm-wiki.md]
- [thedotmack/claude-mem]

### Sources

- [Documentation / Memory]
- [Clark & Chalmers]
- [Schacter & Tulving]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Deciding where memory goes]: #deciding-where-memory-goes
[Giving Claude global memory]: #giving-claude-global-memory

<!-- Knowledge base -->
[AI agents / memory tiers]: ../agents.md#memory-tiers
[AI agents]: ../agents.md
[Claude Code / auto memory]: claude%20code.md#auto-memory
[Claude Code / auto-Dream]: claude%20code.md#auto-dream
[Claude Code / billing]: claude%20code.md#billing
[Claude Code / cross-project sub-agents]: claude%20code.md#cross-project-sub-agents
[Claude Code / sub-agents]: claude%20code.md#sub-agents
[Claude Code / using hooks]: claude%20code.md#using-hooks
[Claude Code]: claude%20code.md
[Lefthook]: ../../lefthook.md
[Ollama]: ../ollama.md

<!-- Files -->
[settings.json file example for own KB]: ../../../examples/claude-code/own-kb/kb.settings.json
[User-level CLAUDE.md example for own KB]: ../../../examples/claude-code/own-kb/user.CLAUDE.md
[User-level settings.json patch example for own KB]: ../../../examples/claude-code/own-kb/user.settings.patch.json

<!-- Upstream -->
[Documentation / Memory]: https://code.claude.com/docs/en/memory
[Manage Claude's memory]: https://code.claude.com/docs/en/memory

<!-- Research -->
[Clark & Chalmers]: https://www.alice.id.tue.nl/references/clark-chalmers-1998.pdf
[Schacter & Tulving]: https://en.wikipedia.org/wiki/Implicit_memory

<!-- Others -->
[karpathy/llm-wiki.md]: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
[rtk-ai/rtk]: https://github.com/rtk-ai/rtk
[thedotmack/claude-mem]: https://github.com/thedotmack/claude-mem
