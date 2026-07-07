# Giving Claude a global memory

Mirrors Claude Code's built-in project-only memory pattern at the user level.

1. [Setup](#setup)
1. [Findings](#findings)
1. [Improvements](#improvements)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

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

## Setup

1. Create the tier's directory:

   ```sh
   mkdir -p "$HOME/.claude/memory"
   ```

1. \[if running Claude Code with the sandbox enabled] Add the tier's directory to `sandbox.filesystem.allowWrite` in the
   **user**-level `settings.json` file. Use an **absolute** path, as `~` does **not** expand in that list.

1. Add permission rules for cross-project access to the **user**-level `settings.json`<br/>

   ```json
   {
     "permissions": {
       "allow": [
         "Read(~/.claude/memory/**)",
         "Edit(~/.claude/memory/**)",
         "Write(~/.claude/memory/**)"
       ]
     }
   }
   ```

   Without these, Claude Code will prompt the user for every memory write from any project other than the one matching
   `$HOME`. The tilde expands for `Read`, `Edit`, and `Write` rules in gitignore fashion.<br/>
   `Bash` rules require literal paths instead; if Claude is meant to manipulate the directory via `git` or other shell
   tools (e.g., to commit the memory tier if it lives in its own repository), add absolute-path patterns like
   `Bash(git -C /Users/<user>/.claude/memory *)` in addition to the above.

1. Add the `@`-import to the **user**-level `CLAUDE.md` file to force Claude Code to load the index at the start of
   every session:

   ```md
   @~/.claude/memory/MEMORY.md
   ```

   The feature does **not** load automatically without this import.

   > [!note]
   > Relative paths in `@<path>` imports resolve relative **to the file that contains the import**.<br/>
   > Imported files can recursively import additional files themselves, up to **4 hops**, and imports inside markdown
   > code blocks are ignored.<br/>
   > Use `/memory` to see exactly which files are loaded via the import chain.

1. Add a one-liner routing rule near the import in `CLAUDE.md` to inform Claude about what belongs where:

   > Global memory is for cross-project behavioral preferences and identity. Project memory is for project-specific
   > context, decisions, and status. When unsure, write to project memory: promotion is easier than demotion.

1. \[optional] Create a `CONVENTIONS.md` file in the memory directory, and `@`-include it from `CLAUDE.md`:

   ```md
   @~/.claude/memory/CONVENTIONS.md
   ```

   This file codifies memory hygiene rules (deduplication, promotion, review triggers) in a file that loads alongside
   the memories it governs. The separate file keeps the main rules file focused on behavior, while keeping
   memory-specific operational details close to their subject.

1. Define the memory entry's format. Each topic file should use a frontmatter scheme:

   ```yaml
   ---
   name: short-kebab-case-slug
   description: one-line summary — used to decide relevance
   metadata:
     type: user | feedback | project | reference
   ---

   Memory content. Link related memories with [[their-name]].
   ```

   The `name` field is the memory's identity. `description` doubles as the index's one-line hook. `metadata.type`
   enables filtering by memory shape. The following types emerged during testing as a reliable routing heuristic:

   - `user`: the user's role, goals, responsibilities, and domain knowledge.
   - `feedback`: guidance the user gave about how to approach work, both corrections and confirmed approaches.
   - `project`: ongoing work, goals, initiatives, bugs, or incidents within a project.
   - `reference`: pointers to where information lives in external systems.

   Use a `[[name]]` linking convention to cross-reference between memories, where `name` is another memory's slug. Links
   to non-existent memories are valid and mark something worth writing later, not an error.

   Saving a memory is a **two-step** process:

   1. Write the topic file with frontmatter and content.
   1. Add a pointer to `MEMORY.md` in the format `- [Title](file.md) — one-line hook`.

   `MEMORY.md` is an **index**, not a memory. Each entry should be one line, under ~150 characters. The detailed content
   belongs in the topic files, not in the index.

1. (Optional) Seed `MEMORY.md` with a small starting bundle of universal preferences. Starting small is deliberate,
   see _Findings_.

## Findings

That Claude could use a global memory system is clear. A survey across 13 project memory directories confirmed this gap
empirically:

- More than 8 entries were duplicated in multiple projects. User profile fragments appeared in 7 projects with
  overlapping content. Autonomy was restated in 4 projects.
- 6 universal behavioral preferences from one session landed only in a single project's auto-memory files. All of them
  generalize beyond the project, none are project-specific. They sat there because the project was the active one when
  they were captured, not because the content belonged there.

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
as part of promotion to the main configuration.<br/>
After six weeks, the tier grew to ~77 topic files across all types, with healthy routing and no cross-project drift.
Context cost (~2000 tokens always-loaded from the index) stayed within the budget of smaller models.

The **type system** (`user`, `feedback`, `project`, `reference`) proved effective as a routing heuristic once deployed.
The types emerged empirically during system design, and map well to the kinds of memories that actually accumulate.
Recording **both** failure **and** success matters for the `feedback` type specifically. If one only saves corrections,
the system drifts away from validated approaches and grows overly cautious. Confirmations of non-obvious approaches
("yes exactly", "perfect, keep doing that") are quieter than corrections, and easier to miss.

Each feedback memory benefits from a structured body. Lead with the rule itself, then a **Why:** line (the reason behind
it) and a **How to apply:** line (when the guidance kicks in).<br/>
The _why_ is load-bearing because it lets a future session judge edge cases instead of blindly following the rule.
Without it, a correction like "don't mock the database" reads as a blanket prohibition; with it ("prior incident where
mocked tests passed but prod migration failed"), a future session can distinguish contexts where mocking is genuinely
fine.

The **linking convention** (`[[name]]`) between memories proved useful for making the memory graph navigable without
requiring a centralized graph. Links to non-existent memories are valuable too, signaling content worth writing later
without blocking the current save.

**Deduplication** and **promotion** rules are essential once the tier grows past ~20 entries. Without explicit rules,
the same correction can accumulate in both project memory and global memory, or a memory can duplicate a `CLAUDE.md`
rule without anyone noticing. To decide:

- When a memory duplicates a `CLAUDE.md` rule or convention (same correction, same scope), fold any unique context into
  the rule, then archive and prune the memory.
- When a correction keeps recurring despite the memory existing, that is the promotion signal: promote it to a
  `CLAUDE.md` rule.
- When uncertain whether the rule fully covers the memory, keep the memory. Pruning a load-bearing entry is worse than
  keeping a redundant one.

The promotion test is always: "would losing this on a fresh host let the same failure recur?" If yes, the rule belongs
in `CLAUDE.md` (cross-host portable). If it is a project-specific fact, it belongs in auto-memory (project-scoped,
accumulated locally). The test is about cross-host portability. A rule can be load-bearing and still fit auto-memory, if
losing it on a different host wouldn't let the same failure recur.

The `@`-import mechanism proved a better loading strategy for operational docs of the memory system (conventions,
reveries guidelines) than `.claude/rules/`. The memory system has mechanical concerns (Claude-writable files, explicit
load ordering, proximity to the routing table) that are incompatible with `rules/`'s implicit-loading, human-curated
ownership model.<br/>
Refer to [Deciding where memory goes] for the full rationale behind the `@`-include vs `rules/` distinction.

## Improvements

- Use a frontmatter scheme on individual topic files (`name`, `description`, `type`) to keep them auditable.

  Without frontmatter, topic files are opaque blobs that require reading the full content to classify. The `description`
  field doubles as the index's one-line hook, so the routing decision and the entry shape stay in sync.<br/>
  The `metadata.type` field allows filtering by memory shape (`user`, `feedback`, `project`, `reference`). This is
  useful when scanning for memories that might need review (e.g. "show me all `project` memories, since project state
  changes fastest").

- Use a `CONVENTIONS.md` file, and `@`-include it alongside the memory index.

  Memory conventions (hygiene triggers, deduplication rules, promotion signals) are a kind of operational logic that
  sits between `CLAUDE.md`'s behavioral rules and the memories themselves. Placing them directly in `CLAUDE.md`
  mixes the different concerns of "how to behave" vs "how to manage memories". Placing them in a separate `rules/` file
  would separate the convention from the thing it governs.<br/>
  The `@`-include pattern resolves this by loading the conventions alongside the memories, which are now placed right
  next to the routing table in the import chain, and `CLAUDE.md` stays focused on general behavior.

  The conventions file should codify:

  - **Hygiene triggers**: event-based review of memorized content, not scheduled. Behavioral rules fire when behavior
    diverges from a memorized rule. Facts fire when an observation contradicts a memorized fact. Patterns fire when a
    divergent approach worked repeatedly.
  - **Deduplication rules**: when to fold a memory into a higher-tier rule and when to keep both.
  - **Promotion signals**: when a correction keeps recurring, that is the signal to promote it.
  - **Archive before delete**: memory directories are **not** version-controlled. Deletions are permanent. Prune only
    after archiving content to a git-tracked location.

- Periodically audit the tier for entries that might belong elsewhere. Apply the "would this fire on a fresh host?"
  test: if yes, the rule belongs in `CLAUDE.md` (cross-host); if it's a project-specific fact, it belongs in auto
  memory. Stale generalizations propagate to every session.

- Consider **linting** the index file at commit-time to catch when it exceeds the 200-line / 25 KB cap.

  Beyond that limit, content silently truncates from context **without warning**. A pre-commit script catching the size
  threshold can prevent silent drift. This is especially important as the tier grows past ~50 entries, where the index
  file can approach the cap without anyone realizing until a critical entry stops loading.

- Prefer surfacing candidate promotions to the user over auto-writing across projects (see _Findings_ on cross-project
  drift).

- Add **cross-memory linking** using a `[[name]]` convention.

  As the tier grows past ~20 entries, related memories become harder to discover from the flat index alone. A
  lightweight linking convention (e.g., `[[name]]` with `name` matching another memory's frontmatter slug) makes
  relationships navigable without requiring a centralized graph. Links to non-existent memories are valid and mark
  something worth writing later.<br/>
  The convention should be **intentionally** light. Heavier approaches (bidirectional link enforcement, graph
  generation) are not really useful unless the tier reaches hundreds of entries.

- Structure `feedback` memories with **Why:** and **How to apply:** lines.

  A correction without its reason ("don't mock the database") reads as a blanket prohibition. With its reason ("prior
  incident where mocked tests passed but prod migration failed"), a future session can judge edge cases. The two-line
  structure (`Why:` + `How to apply:`) captures the reason and the scope without over-structuring the entry. Project and
  reference memories are simpler and do not need this structure.

## Further readings

- [Personal experiments]
- [Propagating knowledge between concurrent sessions]
- [Claude Code]

### Sources

- [How Claude remembers your project]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Claude Code]: ../claude%20code.md
[Deciding where memory goes]: README.md#deciding-where-memory-goes
[Personal experiments]: README.md
[Propagating knowledge between concurrent sessions]: cross-session%20live%20propagation.md

<!-- Upstream -->
[How Claude remembers your project]: https://code.claude.com/docs/en/memory

<!-- Others -->
