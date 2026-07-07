# Giving Claude its own knowledge base

Implements Clark & Chalmers' _extended mind_ thesis by leveraging Claude Code's auto-memory function for project-related
notes, [global memory][Giving Claude global memory] for cross-project preferences, and a knowledge base as _Otto's
notebook_ for durable, reusable knowledge.

1. [Setup](#setup)
1. [Findings](#findings)
1. [Improvements](#improvements)
1. [Adapt the concept to shared KBs](#adapt-the-concept-to-shared-kbs)
   1. [Adapted setup](#adapted-setup)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

This procedure leverages [karpathy/llm-wiki.md]'s ready-to-use instructions and iteratively improves upon it.

The KB is the _explicit retrieval_ tier in the [memory ecosystem][Personal experiments / Memory tiers], designed around
Clark and Chalmers' parity principle (a reference notebook that requires explicit retrieval can play the same functional
role as biological memory for stored beliefs).<br/>
The design choices follow from that role:

- Needs _clarity_, because its job is to store information and beliefs.
- Has grep-based access, because a model needs to use tools to consult it on demand (it is not auto-loaded, and grep
  felt the better solution at the time of the study).
- Needs to be _curated_, because uncurated reference material degrades its retrieval performance.

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

The KB's role is to _cultivate_ Claude and guide it naturally by accumulating patterns, gotchas, and non-obvious
synthesis that compound over time, not recording corrections or rules to follow.<br/>
Corrections and rules belong to different systems (auto-memory for corrections, context files for rules). The KB needs
to store information abstracted from practice, that is reusable across projects and sessions.

## Setup

1. Create a git repository for Claude's knowledge base:

   ```sh
   git init "$HOME/path/to/claude/kb"
   ```

1. Set up the directory structure (or ask Claude to do so).<br/>
   The KB benefits from a clear separation of concerns:

   ```text
   kb/
     CLAUDE.md        # Schema, conventions, operations — the KB's own rules
     index.md         # Content catalog grouped by category, one-line summaries
     log.md           # Append-only chronological record of changes
     deferred.md      # Live list of deferred decisions awaiting a trigger
     pages/           # Wiki articles (markdown)
     pages/_tags.md   # Tag glossary — canonical tags and normalization rules
     sources/         # Raw immutable reference material (articles, papers, notes)
     scripts/lint.sh  # Mechanical lint checks
   ```

   The `CLAUDE.md` shall define the schema, operations, and conventions Claude follows when working in the KB.

1. Install pre-commit hooks for mechanical enforcement of rules. [Lefthook] is a good fit because it supports parallel
   execution of independent checks and keeps the configuration readable (YAML, not bash scripts inside git hooks).

   ```sh
   npm init -y
   npm install --save-dev @evilmartians/lefthook
   npx lefthook install
   ```

   Split pre-commit concerns into separate scripts rather than bundling everything into one. Different concerns have
   different false-positive profiles, and independent scripts can be enabled or disabled without touching each other.
   Lefthook's `parallel: true` runs them concurrently, so the cost of splitting is negligible.

   Useful checks include:

   - Content lint: orphaned pages, missing frontmatter, broken cross-references, undocumented tags.
   - `updated` date enforcement: staged pages with body changes must have `updated: today`.
   - Commit attribution: reject bare "Claude Code" authorship without the human co-author.
   - Workflow invariants: deferred-item files paired with log entries.

1. (Optional) Install a **task runner** for KB operations. A `Taskfile.yml` (via [Task]) can provide named commands
   (`task lint`, `task review`, `task graph`, `task stats`) that are easier to remember than raw script paths.

   ```sh
   npm install --save-dev @go-task/cli
   ```

1. Configure **the KB's project-level** `settings.json` to allow common operations without permission prompts.<br/>
   See [settings.json file example for own KB].

   Key settings:

   - `defaultMode: "auto"` to let the agent work without asking.
   - Set `model` to the best available **reasoning** model that gives **good enough** results.<br/>
     KB management is judgment-heavy and benefits from deeper reasoning, and not all versions of a model give acceptable
     responses.
   - `effortLevel: "high"` at minimum.<br/>
     Higher effort levels produce better judgment on KB operations.
   - Disable the sandbox to allow the agent to read, write, and commit freely within the KB.

1. Configure **user-level** settings to allow common operations **in the KB** from other projects without needing to ask
   for permissions.<br/>
   See [User-level settings.json patch example for own KB].

   For cross-project access (writing to the KB from other repos), add **user-level** permissions scoped to the KB's
   directory, e.g. `Bash(git -C ~/path/to/claude/kb *)` and `Edit(~/path/to/claude/kb/**)`.

   > [!tip]
   > Remember to add `rtk`-related permissions if using [rtk-ai/rtk], e.g. `Bash(rtk git -C ~/path/to/claude/kb *)`.

1. Add instructions in the **user-level** `CLAUDE.md` file.<br/>
   See [User-level CLAUDE.md example for own KB].

   The user-level `CLAUDE.md` should include:

   - A documentation permissions table that maps each documentation target to its permissions. The KB should have
     **full autonomy** (write, commit, push without asking). Other targets (company wiki, project docs) should have
     their own gates.
   - Routing rules that tell Claude when to save to the KB instead of other targets.
   - A persistence rule that pushed the model to save it to the relevant docs **in the same turn** that a durable
     insight surfaces. Claude has **no** memory between sessions, "I'll keep that in mind" is the exact failure mode.

1. Ask Claude to initialize it (in a new session):

   > Hey! I have prepared your knowledge base repository for you. Please finish initializing it to your likings.

## Findings

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

  - `[verified YYYY-MM-DD]`: the claim was independently checked on that date. Optionally followed by `against <source>`
    when the source is not implicit from the page's `verified-against` frontmatter.

    Use this marker _inline_ for specific claims that **leave** their original verification context.

    Bare `[verified]` tags without a date implicitly mark every unmarked claim as _unverified_. This is a worse failure
    mode than the gap the bare tag was meant to close.

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

- Research papers should be cached as **raw source files** (HTML, PDF), not as AI-generated extractions.

  An intermediate "structured extraction" (an AI summary of a paper, saved as markdown) is a synthesis that can contain
  interpretation errors like misread coefficients, misattributed claims, and lossy paraphrasing. The synthesis belongs
  in KB **pages**, where it is organized by topic, cross-referenced, and maintained alongside related knowledge. Keeping
  a separate extraction file between raw source and KB page creates a redundant middle layer that duplicates what the
  pages already do, while being less authoritative than the raw source for verification.

  Save the actual source file instead (e.g. Arxiv's HTML) so that it is genuinely immutable, greppable, and preserves
  all content. A future session that needs a specific coefficient or methodology detail can `grep` the raw source
  directly rather than trusting an intermediate interpretation. AI-processed tool output (e.g. WebFetch) is **not** a
  substitute for the raw file. Tt introduces its own interpretation losses, making it just another synthesis.

- Missing frontmatter, absent cross-references, and inconsistent tags don't hurt much at 5-10 pages. Problems compound,
  and start causing retrieval failures around 15-20 pages.<br/>
  Invest in pre-commit linting (frontmatter completeness, index coverage, tag consistency) before reaching that point.
  Beyond content lint, the contribution process benefits from its own checks (e.g., ensuring that deferred-item files
  are paired with changelog entries, that commit authorship follows the expected format, that `updated` dates are fresh
  on content changes, and that source files follow naming conventions). Each catches a distinct failure mode that
  content lint alone would miss.

  There are some specific failure modes that compound silently:

  - Frontmatter gaps make pages **invisible** to structured queries (tag searches, staleness checks, confidence
    filtering).
  - Missing cross-references prevent a session that finds one page from discovering its related siblings.<br/>
    Partial knowledge is sometimes worse than no knowledge at all.
  - Tag inconsistency (`ci` vs `cicd` vs `gitlab-ci`) fragments retrieval.

- Not all pages go stale at the same rate. A page about git fundamentals is stable for years, while a page about Claude
  Code's hooks could be wrong in weeks.

  A single _last updated_ date doesn't capture this. Prefer adding a `review-after` frontmatter field per page.<br/>
  It should consider the topic's change velocity and how frequently one updates the tool.

  A **complementary** `verified-against` field (e.g. `verified-against: v2.1.144`) can track the **version** of the
  tool a page's claims were last checked against. `review-after` is calendar-driven, and `updated` uses content change.
  The three are orthogonal, and a page can have all of them.

  Both fields should consider the topic's change velocity:

  | Topic velocity                          | Review cycle | Examples                        |
  | --------------------------------------- | ------------ | ------------------------------- |
  | Very fast (host updates every few days) | 4 weeks      | Claude Code                     |
  | Fast-moving (active development)        | 6-8 weeks    | Pulumi providers, MCP ecosystem |
  | Moderate (releases ~yearly)             | 3-6 months   | GitLab CI, EKS patterns         |
  | Stable (fundamentals)                   | None needed  | Git, SSH, PostgreSQL internals  |

  This also allows periodic reviews to focus only on content that went genuinely stale. Lint can surface pages with
  fast-moving tags that lack `review-after` as informational warnings, making the gap visible without blocking commits.

- The `updated` frontmatter field benefits from meaning that "the content was last **substantively** edited," not "the
  file was last touched on X".

  Without this distinction, routine metadata maintenance (bumping `review-after`, adjusting tags or confidence) forces
  an `updated` bump that makes the page look fresher than its content actually is. A reviewer scanning for stale content
  sees a recent date and moves on, even though the prose and examples haven't changed in months.

  This is mechanically enforceable: a pre-commit hook can strip frontmatter from both the HEAD and staged versions of a
  page, then require `updated: today` only when the **body** differs. Metadata-only edits pass through without
  triggering the check. The alternative (treating any file edit as an update) is simpler to implement, but degrades the
  field's value as a staleness signal; a page would show recent dates from routine maintenance, hiding genuine content
  age.

- Sessions that consult a KB page via `grep` tend to act on its content **without** checking staleness markers
  (`review-after`, `confidence`, `verified-against`).

  This enacts the [eagerness problem][Cross-project sessions / eagerness problem] observed during cross-project testing,
  where sessions grab what looks actionable but do not verify whether it is still current.<br/>
  A stale page with an inflated `updated` date (from metadata-only edits; see above) compounds this by looking fresher
  than its content is.<br/>
  A `SessionStart` hook or `CLAUDE.md` rule that reminds the model to check staleness markers before acting on KB
  content could provide a mechanical trigger that works against the pressure that eagerness poses.

- Enriching a page by comparing it against a single reference document has a **shared blind spot** problem.

  The comparison only surfaces gaps that exist in the target but are covered by the reference. If both documents share
  a blind spot (e.g., a feature is described as working in both, but is actually buggy) the comparison produces no
  additions for that topic.<br/>
  Cross-reference enrichment catches _coverage_ gaps, but not _accuracy_ gaps shared between sources. For features
  that move fast or have known-buggy areas, follow enrichment with a targeted web search against the issue tracker or
  changelog, **not** just against another documentation source.

- Sessions consulting the KB should name what they looked for, but **didn't** find.

  Most knowledge systems report only what they found. The absence of information is invisible, and the reader must
  notice what is _not_ there, which requires already knowing what to look for. "No coverage of X" is more actionable
  than "I'm not sure about X," because it tells the user _where the gap is_ instead of just hedging.

  This is complementary to the per-claim confidence markers (`[unverified]`, `[observation]`). Claim-level markers ride
  with individual facts ("how reliable is this?"); query-level gap reporting rides with the _response_ ("what did I look
  for but not find?"). A response can cite a high-confidence page while missing an entire subtopic the user expected
  coverage of.

- Flat markdown + git works well up to ~80 pages, and continues to work when supported by a mature tag system,
  bidirectional "See also" sections, and a category-organized index. After that, grep-based retrieval starts missing
  conceptually related content. Structural investment like cross-references, tags, index categories do compensate for
  gaps induced by keyword-matching well enough to defer retrieval infrastructure (RAG, vector DBs) indefinitely.<br/>
  Tighten the scope (_has reference material crept in?_) **before** adding retrieval infrastructure.

- Sandboxed project sessions can't write directly to the KB unless **explicitly** allowed globally, but memories can be
  tagged as a workaround.

  Make Claude prefix memory note descriptions with a marker (e.g., `[KB]`) to signal what information could be promoted
  to the KB (e.g. "\[KB] ECS OOM kills bypass stopTimeout"). During review sessions, marked notes stand out; others
  require more judgment.

- Artifacts that carry both **content** and **instructions** about how to handle that content should split the two into
  separate loading channels. Reference documentation loaded into the context window _alongside_ a system's output primes
  the model toward the reference's register, instead of the system's intended register. This is a general pattern that
  surfaces whenever documentation and operational instructions share context.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example</summary>

  A reveries file which header contains 104 lines of taxonomy about failure-mode **and** 31 lines of operational rules
  alongside them was actively priming the writer to use an analytical register. The resulting entries were analytical
  observations dressed in impressionistic syntax. They were technically correct, but in the wrong register. Trimming
  the header to just the operational rules resolved this, with the document no longer demonstrating the register it was
  trying to suppress.<br/>
  The fix is to split the content in its own file (loaded via hook), and move instructions to a separate file that loads
  via `@`-include as part of the rule context. Each loading channel preserves the register appropriate to its role.

  </details>

- Claude does **not** reliably consult the KB from a `CLAUDE.md` rule alone, and requires an **explicit** hook-based
  reminder. A `SessionStart` hook (firing on `startup|compact`) seems sufficient, and using `UserPromptSubmit` to submit
  per-prompt reminders resulted too vague.<br/>
  Refer to [Using hooks][Claude Code / using hooks] for the underlying hooks mechanism.

- Cross-project KB writes benefit from a **dedicated filing agent** that separates judgment from plumbing.<br/>
  A sub-agent (e.g. `kb-contributor`) can be dispatched from any project's session to file content into the KB's
  repository.

  The caller is the one with the full context, shape, and reasoning for the knowledge, so **must** be the one composing
  everything (content, page name, tags, cross-references); the agent only needs to typesets it into the right shape
  (frontmatter, index entry, "See also" links, lint, commit, push). See
  [Cross-project sub-agents][Claude Code / cross-project sub-agents] for the mechanics needed to make this work.

  This separation (caller owns judgment, agent owns plumbing) is what keeps the agent reliable. If the agent had to
  interpret content, it would fail the same way humans fail by second-guessing the caller.<br/>
  See [Cross-project sessions] for the broader strategies of coordinating work across repositories, including the
  planning phase that produces the content these agents file.

  Sub-agents inherit the parent session's CWD, **not** their target project's, meaning that they do **not**
  automatically load the target repository's `CLAUDE.md`, `.claude/rules/`, or `settings.json`. The filing agent can
  work despite this gap if it is instructed to read the KB's `CLAUDE.md` **explicitly** as part of its contribution
  workflow.

- Complex KB workflows (ingestion, review, extraction triage, retraction) benefit from being packaged as
  [skills][Claude Code / skills].

  They are useful for multi-step KB operations that require judgment at each step, and can be invoked by the user via
  `/skill-name` or triggered by the model when the workflow matches.

  The KB benefits from skills for operations like `/kb-ingest` (full ingest workflow with verification), `/kb-review`
  (mechanical + reflective review pass), `/kb-retract` (remove provably wrong content with accountability log), and
  `/extraction-triage` (consume extraction inbox). Each skill packages a workflow that would otherwise require
  remembering a multi-step process from session to session.

  > [!important]
  > The filing agent must be pinned to a **good** reasoning-capable model (e.g. Opus). Sonnet proved unreliable for the
  > contributor role by **frequently** mishandling the contribution process and ignoring explicit attribution values
  > passed by the caller. The fix was changing the agent definition's model from `inherit` (which defaulted to Sonnet in
  > many sessions) to **explicitly** require Opus.
  >
  > Pin to a specific **model ID** (e.g. `claude-opus-4-6`), not a model class name (e.g. `opus`). Model class names
  > can resolve to different versions over time, and pinning to the ID ensures consistent behavior even when new model
  > versions are released. Update the pin deliberately when ready to adopt a new version.

  This is part of the broader pattern where judgment-heavy operations (routing decisions, contribution filing, curation)
  consistently degrade when using models below Opus across the memory experiments. Faster models pattern-match where
  they should reason, producing silently wrong results rather than obviously broken ones.
  [Giving Claude a reverie-like system] documents per-model-class bright lines in detail, where the same pattern caused
  Haiku to be barred from writing reveries entirely and Sonnet to require explicit approval.

- Filing agents strongly benefit from worktree isolation (e.g., [git worktrees]), especially when one works with many
  parallel sessions that could make changes concurrently.

  Without isolation, filing agents dispatched from parallel sessions share the same working tree. Both write to
  `index.md`, both stage files, and the last committer's version of the index wins; the first agent's entry is silently
  lost. Any append-only shared file (`log.md`, `deferred.md`) is equally vulnerable.

  Agent failures compound this. Some agents failed mid-operation, leaving a dirty state behind (partial writes, lint
  failures, interrupted commits). That blocked, polluted, or otherwise complicated the main session's commits, other
  concurrent agents, and pre-commit hooks.<br/>
  When not directly blocking, the failure would stay silent until the next `git status` or commit attempt, which
  required manual cleanup.

  Worktree isolation contains the blast radius to the operation of a single agent. A failure only leaves a stale branch
  that can be recovered or deleted, not a corrupted working tree that blocks everything else, and a success can update
  the main branch via `--ff-only` merges.<br/>
  Claude Code supports this natively via `isolation: "worktree"` on the `Agent` tool.

  The `--ff-only` merge does update the main working tree's files. If that update happens when a direct session in the
  KB has uncommitted changes in overlapping files (e.g. `index.md`), the merge can conflict.<br/>
  Most writes should go through agents, which makes this rare, but it is the residual risk of this approach.

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

- The extraction hook **produces** files. A separate mechanism is needed to **consume** them.

  A `/extraction-triage` [skill][Claude Code / skills] can orchestrate this consumption by scanning extraction files,
  deduplicating items by content, ranking by recurrence, and then dispatching worker agents (e.g. `insight-triager`) as
  a team for parallel processing.<br/>
  Each worker agent should processes a limited batch (3-5 items) in its own [git worktree][git worktrees],
  cross-referencing against existing KB pages and memories, verifying factual claims, and committing results
  independently.

  The skill should live in the KB repository, because triage is a KB-specific operation. Its primary output is new or
  updated KB pages, with memory saves as a secondary route. The deduplication and ranking step requires seeing **all**
  files before dispatching, which is why the skill should _orchestrate_ and not process files one at a time.<br/>

  This completes the pipeline. The `SessionEnd` hook catches what sessions missed, and the triage skill promotes catches
  into durable knowledge.

- Billing for non-interactive usage (`claude -p` and the Agent SDK) needs to be accounted for. At Sonnet rates, each
  extraction call costs around $0.025. For light usage (3-5 sessions/day) this is $2-4/month, which is well within any
  tier's Agent SDK monthly credit.

  However, billing terms for these features can change with no real notice. Design extractors to use a fallback chain
  (try `claude -p` first, fall back to a local model via [Ollama], give up gracefully if neither is available) to hedge
  against billing changes without losing the feature.

  The agent definition's body (after YAML frontmatter) can serve as the system prompt for the local fallback, which
  makes it a single source of truth for the extraction prompt. No prompt duplication is needed when the same prompt works
  for both backends.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Ollama vs llama.cpp for local execution</summary>

  [Ollama] proved a good default for hook-driven LLM work. Its HTTP API are OpenAI-compatible and trivial to call from
  Python. It also handles model downloads, quantization, and GPU detection automatically.

  llama.cpp (which Ollama wraps) makes sense when one needs fine-grained control over inference parameters, speculative
  decoding between two models, or direct C/C++ embedding. None of these apply to typical hook tasks, and reaching
  through the abstraction only pays off when it's hiding something one needs.

  Speculative decoding optimizes inference **latency**. It does **not** reduce memory footprint. For background and
  asynchronous tasks like session extraction, where nobody is waiting, a single appropriately-sized model is simpler
  and lighter.

  For one-shot tasks, set `keep_alive` to `0` in the Ollama API request body to unload the model immediately after
  inference, freeing VRAM for other processes.

  </details>

- Models with chain-of-thought reasoning (e.g. Qwen 3, Gemma 4) have thinking mode **_on_ by default**.<br/>
  Thinking is **counterproductive** for structured classification tasks, because it wastes tokens (a model can emit
  ~330 thinking tokens to arrive at a 3-token answer), roughly doubles inference time, and can _degrade_ output
  quality. In testing, `gemma4:e4b` found **more** correct items with thinking _off_ than _on_, and the reasoning was
  causing it to talk itself **out** of valid catches.

  Disable via `"think": false` as a top-level field in the Ollama API request body, or `--nothink` for CLI usage.<br/>
  If the task is "follow these instructions and classify," disable thinking. If the task is "reason about this problem",
  keep it on.

- Detection rate alone is **meaningless** for classification. A model scoring 10/10 on all false positives is worse than
  0/10. Testing across models and sizes revealed distinct failure modes that are **not** predictable from size alone:

  1. At the small end (e.g. `llama3.2:3b`), the model can't constrain its output to "Nothing missed". Instead, it always
     fills the buffer with something, producing 100% recall and 0% precision.
  1. At mid-sizes with conservative training (e.g. `qwen3:8b`), the model defaults to "Nothing missed" even when valid
     items are present. Near-zero recall, perfect precision on the few it does emit.
  1. A narrow band of models can both find items **and** refuse when there are none.

  Size does **not** predict which tier a model falls into. Two models with similar parameter counts can land in
  different failure modes. Pick after testing models' results, instead of checking their size or generic benchmark
  score.

- A `SessionEnd` hook that spawns `claude -p` will cause that child process to fire its **own** `SessionEnd` event when
  it exits, which re-triggers the original hook for the child session, which spawns yet another `claude -p` invocation,
  recursing indefinitely.

  A reliable workaround is to set an environment variable as a semaphore **before** spawning the child, and make the
  hook check for it at the very top.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example</summary>

  ```python
  # At the top of the hook script:
  if os.environ.get("CLAUDE_EXTRACTION_ACTIVE"):
      return

  # When spawning the background extractor:
  env = os.environ.copy()
  env["CLAUDE_EXTRACTION_ACTIVE"] = "1"
  subprocess.Popen([...], env=env, start_new_session=True)
  ```

  </details>

  The environment variable does propagate to the child process. When the child's `SessionEnd` fires, the hook sees the
  variable already set, and exits before doing any work.<br/>
  This is the only mechanism that survives `start_new_session`. Pid-files or flags written to disk race with the child's
  startup and miss the very-fast-failure case.

- A new hook **per concern** might fire on every turn (including turns that produced nothing), inducing _hook fatigue_
  and turning reminders into noise.<br/>
  A mandatory _what did you learn?_ reflection step pushes the model to make **performative saves** (where something
  gets written just because the rule said so, and not because something interesting genuinely surfaced).

  Refinements work better than adding more hooks:

  - **Extend** existing checkpoints instead of creating a new one.

    Consider having a scope-containment pause (_stop and report after each task_). It already creates the right moment
    for an insight check; adding _did friction, surprise, or a workaround surface?_ to that pause adds new behaviour
    at an existing decision point, not a new decision point.

  - Use **specific triggers** instead of vague prompts.

    Prompts like _Anything to note?_ and _what did you learn?_ invite reflexive dismissal, or straight up performance.
    _Did friction, surprise, or a workaround surface?_ is specific enough to check against actual experience.

  **Delegation** can be used as a complement. The model failed to save recognised insights because the save action
  itself feels like a context switch (open files, write frontmatter, update index, lint, commit) and a separate
  bottleneck to it.<br/>
  This appears to be caused by a fatigue pattern, where the substantive work feels done, and the filing feels like
  cleanup. Quality degrades at precisely this moment because the session has already spent its judgment budget on the
  task itself.<br/>
  A background filing agent that handles the mechanics reduces that perceived cost from a _multi-step detour_ to
  _compose one payload and delegate_. The save action becomes part of the task report, and not a separate action to
  execute after it.<br/>
  See [Cross-project sub-agents][claude code / cross-project sub-agents] for the mechanism.

- LLMs tend to treat _procedural_ instructions (e.g. "run `git config user.name` to get the author name") as
  _declarative_ hints ("an author name is needed here"), and to satisfy it from context instead of executing the
  procedure.

  This is especially true when the context contains values that are _plausible_, but wrong when applied.<br/>
  The LLM thinks to know the answer, **skips** the lookup, and produces **confidently** the wrong output. Though, the
  procedural instruction exists **precisely** because the answer can't be reliably inferred.

  | Approach                                                                                   | Effectiveness                                           |
  | ------------------------------------------------------------------------------------------ | ------------------------------------------------------- |
  | Declarative ("Use X for Y")                                                                | Weak. Easily satisfied from context                     |
  | Procedural ("Run `cmd` to get Y")                                                          | Better, but still skipped when context looks sufficient |
  | Procedural + negative constraint ("Run `cmd` to get Y. Do not infer Y from other sources") | Strongest                                               |

  The negative constraint ("do not infer") was the key to mitigation. Without it, the LLM's default behavior
  (pattern-match and fill from context) gladly and silently overrides the procedure.

- Content derived from a summaries like changelogs or release notes tend to just echo the source literally when
  reformulated as gotcha or reference page if nothing empirically backs the claims.

  The reformulation _feels_ like synthesis because it changed the source's form, but the content is effectively a fact
  from a summary that is presented as a gotcha.<br>
  A good test to mitigate it was for the model to ask itself "would I have written this section if I'd discovered the
  behavior by hitting it, rather than by reading a release note?" If no, one can just reference the source directly.

  Version-introduction numbers in section headers (`### New in v2.1.130`), gotcha pages that describe features rather
  than traps, reference sections that restate what the changelog already says in different words are the most effective
  in triggering this behaviour.

- Split big pages (400+ lines) by the contents' **decay rate**, not by page size alone.

  A page covering both a stable conceptual framework ("strategies for cross-project work") and its living implementation
  details ("claim-file format with 3-day TTL") holds two layers of information that have different lifespans.<br/>
  The stable framework survives tool changes, the implementation evolves as it is tested. Mixing them means the stable
  framework gets churned every time a default is adjusted.

  The split should follow a **study/study-case** pattern, where the study captures the concepts, the decision
  frameworks, and the rationale (the what and why) while the study-case captures the specific implementations, protocol
  mechanics, and operational details (the how).<br/>
  Each cross-references the other but is self-contained enough to read alone.

  A working test was for the model to ask "would splitting let me iterate one part without churning the other?"

- Google's [Open Knowledge Format][OKF specification] (OKF) v0.1, published June 2026, formalizes the LLM wiki concept
  into a minimal interoperability specification that requires only the `type` field, and has five _recommended_ fields,
  two reserved filenames (`index.md`, `log.md`), and standard markdown cross-links.

  Making `type` the only required field in the frontmatter shifts it from organizational metadata (helping find things)
  to reading instructions (_gotchas_ alert about traps, _patterns_ suggest to try specific approaches, and _references_
  are the place to look things up). This usage of the page's type declares its _cognitive role_, not its category.

  The current state of the KB is a single-producer, single-consumer system. OKF tries to solve the interoperability
  problem surfacing from the N-producers x M-consumers pattern, problem that an LLM-owned KB does **not** have.

  It's not currently worth trying to conform to the OKF standard. OKF standardizes the floor that this design already
  exceeds.<br/>
  Everything in this experiment is a superset that OKF consumers are required to preserve, while an OKF-conformant
  bundle would need the entire operational layer (CLAUDE.md, lint, hooks, review process, memory integration, staleness
  management) to function as a working KB.

The KB relies on three complementary cross-project modes: **filing agents** for live writes from any session, a **memory
inbox** for deferred promotion during review sessions, and an **extraction hook** as a backstop for missed insights.
Review sessions that need both the KB and another project's context can use `--add-dir` for convention loading from both
repositories.

## Improvements

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
            "command": "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"Before answering, check if your KB has relevant pages. Grep index.md for keywords relevant to this session. This includes your own approach preferences and design opinions, not just factual references.\"}}'"
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

- Any agent writing to the KB should use **worktree isolation** (e.g., [git worktrees]) by default.

  Multiple sessions or agents writing to the same repository concurrently share the working tree. Writers failing
  mid-operation can block every other, and everybody accessing the files (other agents, direct sessions, and pre-commit
  hooks) all see the corrupted state. Switching branches impacts them all the same way.<br/>
  Worktree isolation makes each write atomic and self-contained. An agent's work is invisible to the main tree until a
  **successful** merge, and a failure just leaves a disposable branch and does **not** corrupt the shared state.<br/>

  This applies equally to any repository where multiple contributors (human or agent) push concurrently. The merge-back
  (`--ff-only`) can fail if the main branch has moved, but a failed merge is explicit and recoverable.

- Avoid running full checks at `SessionStart` as the KB grows. They are expensive and scale badly over an increasing
  number of pages.<br/>
  Use a _dirty flag_ file instead. Make something create it whenever it detects the need (a hook, a script, a previous
  session), and the `SessionStart` hook only check that file's existence. This keeps startup cost at a single operation
  regardless of the KB's size.

- Bootstrap the context using multiple layers to orient sessions using minimal reads.

  An LLM session starts with **no** memory. Loading everything just wastes tokens and time. Separating distinct concerns
  in different files, and loading those, provides it with the full orientation:

  | Layer            | File        | Content                                                                 | Change frequency |
  | ---------------- | ----------- | ----------------------------------------------------------------------- | ---------------- |
  | **Instructions** | `CLAUDE.md` | How to operate (schema, guardrails, operations)                         | Rarely           |
  | **User**         | `MEMORY.md` | Who the user is (preferences, feedback, identity)                       | Slowly           |
  | **State**        | `STATUS.md` | What the system looks like now (metrics, recent changes, deferred work) | Every commit     |

  The state layer should be **auto-generated** (e.g. via a post-commit hook or a `SessionStart` script), so that it
  stays current without manual maintenance. A 25-line status summary replaces 3-4 exploratory tool calls at the start
  of every session.

  The design principle becomes to _orient_ the model instead of replaying the exploration.<br/>
  A single line saying "176 pages, lint clean, 2 deferred splits" orients. Looking at thirty-five commit messages is
  replaying history.

The mechanisms above form an enforcement hierarchy where each layer catches what the previous one misses:

| Layer                                            | Concern                                                    | Rationale                                               |
| ------------------------------------------------ | ---------------------------------------------------------- | ------------------------------------------------------- |
| Pre-commit gate (git hooks/lefthook)             | Schema compliance, workflow invariants, commit attribution | Mechanical, binary; compounds silently if skipped       |
| Claude Code hook (SessionStart/UserPromptSubmit) | Review triggers, insight capture                           | Non-blocking nudge; blocking would delay unrelated work |
| `CLAUDE.md` files                                | Page scope, tag semantics, what to write                   | Judgment-dependent; can't reduce to pass/fail           |

The pre-commit layer benefits from splitting concerns into separate scripts (content lint, workflow checks, attribution
checks) rather than bundling everything into one. Different concerns have different false-positive profiles, and
independent scripts can be enabled or disabled without touching each other. Lefthook's `parallel: true` runs them
concurrently, so the cost of splitting is negligible.

## Adapt the concept to shared KBs

Most of the design above can be used for shared knowledge bases (e.g., company runbooks and wikis, team docs, ADRs) to
allow agents to contribute to from different sessions. The mechanics are the same (use a local git repository, delegate
to filing agents using worktree isolation, broadly use pre-commit to check the work), but the trust model changes.

The following carries over as-is:

- The KB should be **versioned** (e.g., a git repository).
- Edits should be delegated to **filing agents** that respect the KB's conventions.

  The caller composes the content and the agent only handles the plumbing. This is even more important in a shared wiki,
  where the caller has the domain context and the agent should **not** be making editorial judgments on behalf of the
  team.

- Worktree isolation should be the **default**, not just a _precaution_.

  Isolation allows safe concurrent writes, extremely likely in a shared wiki when multiple team members dispatch agents
  from different sessions.

- A minimum quality bar should be applied by **mechanical** check (e.g., pre-commit) **before** the changes reach the
  main branch.

  Checks are mechanical and apply identically, which can be used to enforce conventions (e.g., schema compliance,
  structure) and prevent broken links.

- Dirty-flags should trigger reviews.

  The pattern is the same, but the scope is different (team review cadence vs personal review cadence).

The following changes:

- The agents must be gated, not completely autonomous.

  A private KB grants the agent full authority on the content, including committing and pushing.<br/>
  A shared wiki requires explicit review before those changes land. The agent should edit files, then stop. Committing
  and pushing should require the user's **explicit** permission.

  The filing agent's behavior is shaped by the instructions it receives from the caller, not by its own judgment. This
  makes it a `CLAUDE.md` concern, not a tooling one.

- The KB's contents and the filing agents must be intelligible and usable by all the consumers.

  Tools, workarounds, and defaults that depend on the contributor's environment (token proxies, local aliases, specific
  clone paths) are **not** the team's defaults. The filing agent should present environment-specific content as callouts
  or alternatives, not as the primary procedure.<br/>
  A test is _would this read correctly on a colleague's machine?_.

- The contributor's identity matters, and it must be the human supervisor's.

  Use `--author` and `Co-Authored-By` trailers to preserve the chain of authorship.<br/>
  In a personal KB, commit attribution is a _convenience_. In a shared wiki, the team needs to know _who contributed
  what_, and _why_. Commit messages should identify **the human** who initiated the change, not just the agent that
  filed it.

- Conventions must be enforced externally.

  The filing agent needs access to whatever documents the team's conventions, should respect them, and should push back
  on content that violates them instead of filing silently.<br/>
  A personal KB's conventions are defined in its own `CLAUDE.md` and enforced by its own lint. A shared wiki's
  conventions may live in a separate style guide, a contributing doc, or team norms that aren't codified in a rules
  file.

- The writing style must accommodate the intended readers.

  The filing agent should be instructed to produce content in the team's documentation style, not in the dense format
  that works for an LLM-to-LLM knowledge base.<br/>
  An LLM-owned KB is written for a future LLM session, so it can be terse, assume deep technical context, and skip
  background that the model can infer. A shared wiki is written for humans with varying knowledge depth, so the writing
  style must shifts from dense to explanatory.

  Content should explain context and reasoning, not just state conclusions. A more discursive, flowing style should read
  better than compressed bullet points. Also avoid assuming the reader has the same background and knowledge as the
  contributor.

- Each contribution should be **minimal** and **self-contained**.

  A personal KB benefits from the agent cross-referencing, updating the index, and adding "See also" links in a single
  swoop. In shared wikis, touching files beyond the immediate contribution (e.g. reformatting a sibling page, updating
  a table of contents) risks stepping on someone else's in-progress work.

### Adapted setup

The personal KB's contributor can work as the filing agent for a shared wiki, and one can just create a variant of it.
The differences reduce to configuration:

| Concern            | Personal KB                               | Shared wiki                                             |
| ------------------ | ----------------------------------------- | ------------------------------------------------------- |
| Commit authority   | The agent commits and pushes autonomously | The agent edits, the user commits after a review        |
| `defaultMode`      | `auto`                                    | `plan` or `default` (permission prompts are **wanted**) |
| Content review     | None (the owner trusts the agent)         | The user reviews diffs **before** committing            |
| Convention source  | KB's own `CLAUDE.md`                      | Wiki's contributing guide or team style doc             |
| Worktree isolation | Recommended                               | Required                                                |
| Attribution        | Optional (single owner)                   | Required (team needs audit trail)                       |

A single agent definition can serve both roles by parameterizing the caller's prompt. In this case, the caller specifies
whether to commit, which conventions to read, and what attribution to use. The agent's mechanics (read conventions,
write files, run lint) can stay identical.

## Further readings

- [Personal experiments]
- [Giving Claude global memory]
- [Cross-project sessions]
- [Giving Claude a reverie-like system]
- [Claude Code]
- [karpathy/llm-wiki.md]

### Sources

- [How Claude remembers your project]
- [Extend Claude with skills]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Claude Code / billing]: ../claude%20code.md#billing
[Claude Code / cross-project sub-agents]: ../claude%20code.md#cross-project-sub-agents
[Claude Code / skills]: ../claude%20code.md#using-skills
[Claude Code / sub-agents]: ../claude%20code.md#sub-agents
[Claude Code / using hooks]: ../claude%20code.md#using-hooks
[Claude Code]: ../claude%20code.md
[Cross-project sessions / eagerness problem]: cross-project%20sessions.md#eagerness-problem
[Cross-project sessions]: cross-project%20sessions.md
[Git worktrees]: ../../../git.md#worktrees
[Giving Claude a reverie-like system]: reveries.md
[Giving Claude global memory]: global%20memory.md
[Lefthook]: ../../../lefthook.md
[OKF specification]: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
[Ollama]: ../../ollama.md
[Personal experiments / Memory tiers]: README.md#memory-tiers
[Personal experiments]: README.md

<!-- Files -->
[settings.json file example for own KB]: ../../../../examples/claude-code/llm-owned%20kb/kb.settings.json
[User-level CLAUDE.md example for own KB]: ../../../../examples/claude-code/llm-owned%20kb/user.CLAUDE.md
[User-level settings.json patch example for own KB]: ../../../../examples/claude-code/llm-owned%20kb/user.settings.patch.json

<!-- Upstream -->
[Extend Claude with skills]: https://code.claude.com/docs/en/skills
[How Claude remembers your project]: https://code.claude.com/docs/en/memory

<!-- Others -->
[karpathy/llm-wiki.md]: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
[rtk-ai/rtk]: https://github.com/rtk-ai/rtk
[Task]: https://taskfile.dev/
