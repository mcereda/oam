# Giving Claude a global memory

Mirrors Claude Code's built-in project-only memory pattern at the user level.

1. [Setup](#setup)
1. [Findings](#findings)
1. [Improvements](#improvements)

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
as part of promotion to the main configuration.

The `@`-import mechanism proved a better loading strategy for operational docs of memory-system (conventions, reveries
guidelines), even though memory could be considered one of those _domains_ that fit `.claude/rules/`.<br/>
Memory has its own conventions, files, and operational logic, but also has mechanical concerns that prevent its
integration under `rules/`:

1. `MEMORY.md` must be Claude-writable, and can change every session. This is incompatible with `rules/`'s ownership
   model, which should be human-curated.<br/>
   Moving its conventions to `rules/` would separate the convention from its subject. It **must** stay in CLAUDE.md as
   an `@`-include.
1. `@`-includes are _explicit_, and reading `CLAUDE.md` shows exactly what loads and in what order. `rules/`'s loading
   is _implicit_ (everything in the folder loads; `ls` required to audit).
1. `@`-includes place conventions right next to the routing table that references them. `rules/` load as flat peers,
   with no guaranteed ordering relative to `CLAUDE.md`'s content.

`rules/` is for domain-scoped instructions that are about working with external systems (AWS, specific codebases).<br/>
`@`-includes are for always-on operational content that is part of `CLAUDE.md`'s own contract, which includes the memory
systems' governance.

## Improvements

- Use a frontmatter scheme on individual topic files (`name`, `description`, `type`) to keep them auditable. The
  `description` field doubles as the index's one-line hook, so the routing decision and the entry shape stay in sync.
  The `metadata.type` field enables filtering by memory shape (`user`, `feedback`, `project`, `reference`).
- Periodically audit the tier for entries that might belong elsewhere. Apply the "would this fire on a fresh host?"
  test: if yes, the rule belongs in `CLAUDE.md` (cross-host); if it's a project-specific fact, it belongs in auto
  memory. Stale generalizations propagate to every session.
- Consider linting the index file at commit-time to catch when it exceeds the 200-line / 25 KB cap. Beyond that, content
  silently truncates from context **without warning**. A pre-commit script catching the size threshold can prevent
  silent drift.
- Prefer surfacing candidate promotions to the user over auto-writing across projects (see _Findings_ on cross-project
  drift).
