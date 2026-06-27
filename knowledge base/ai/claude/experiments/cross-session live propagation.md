# Propagating knowledge between concurrent sessions

An emergent capability of Claude Code's file-watching mechanism is that it allows active sessions to receive knowledge
from sibling sessions in real time, with no additional infrastructure.

1. [TL;DR](#tldr)
1. [Setup](#setup)
1. [Findings](#findings)
1. [Improvements](#improvements)
1. [Open questions](#open-questions)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Claude Code sessions are designed as isolated units. Each starts with the same auto-loaded files (`CLAUDE.md`,
`MEMORY.md`, settings) but operates independently, with no built-in mechanism to notify sibling sessions about
discoveries made during a run.<br/>
The harness does, however, watch auto-loaded files for changes throughout a session's lifetime. This was built to keep
sessions aware of external edits (linter rewrites, user changes to CLAUDE.md), but it showed the unintentional side
effect that, when one session saves a memory, the change to `MEMORY.md` triggers a notification in **every** active
session that loaded that same file. The same applies to `CLAUDE.md` edits.

This turns the memory system into a live broadcast bus between concurrent sessions, with the existing
[memory-tier scoping][Personal experiments / Memory tiers] providing relevance filtering at no additional cost.

## Setup

The mechanism requires ho hooks, no scripts, no additional configuration. The file-watching mechanism does the work.

The **project-level** `MEMORY.md` is loaded automatically by Claude Code's built-in
[auto-memory][Claude Code / auto memory] feature, so it already works as the active broadcast bus for sessions working
in the same project.

**Cross-project** propagation (broadcasting to sessions in different repositories) requires the
[global memory][Giving Claude a global memory] tier to be configured, so that its own `MEMORY.md` is `@`-imported from
the user-level `CLAUDE.md`file. Without it, propagation stays scoped to same-project siblings.

1. Start two or more sessions in the same project.
1. Save a memory in one session. The change to `MEMORY.md` triggers a system-reminder injection in every sibling session
   that loaded that file.
1. (Optional) Configure [global memory][Giving Claude a global memory] to extend this propagation **across** projects.

## Findings

The harness watches auto-loaded files (`CLAUDE.md`, `MEMORY.md`) for changes, and **continues** watching them throughout
the session's lifetime. When **any** process (another session, a linter, the user, a hook) modifies a watched file,
**every** active session that loaded it receives a system-reminder containing the updated content.

The injection reads as follows:

> Note: \[path] was modified, either by the user or by a linter. This change was intentional, so make sure to take it
> into account as you proceed.

This behaviour is **not** documented by Anthropic. It was discovered **empirically**, and verified using deterministic
marker tests on 2026-06-26. Public documentation describes `MEMORY.md` as loaded at session start, with **no** mention
of live change notifications between concurrent sessions.

> [!important]
> The mechanism is an _implementation detail_ of Claude Code, not a protocol nor a guarantee. Other coding assistants
> (Cursor, Windsurf, custom CLI wrappers) may not watch auto-loaded files the same way, or at all.<br/>
> Since Claude Code is Anthropic's official and only sanctioned harness for Claude, the behavior is reliable for all
> standard usage, but it is not portable to arbitrary environments and could be "fixed" at any time.

| File changed                                        | Who gets notified                       | Granularity       |
| --------------------------------------------------- | --------------------------------------- | ----------------- |
| Global `~/.claude/CLAUDE.md`                        | All active sessions on the same machine | Full file content |
| Project `CLAUDE.md`                                 | Sessions in the same project            | Full file content |
| Global `~/.claude/memory/MEMORY.md` (if configured) | All active sessions on the same machine | Full file content |
| Project `memory/MEMORY.md`                          | Sessions in the same project            | Full file content |
| KB pages, arbitrary files (if configured)           | No notification                         | Not watched       |

Files outside the auto-loaded set (KB pages, arbitrary project files, source code) do **not** trigger notifications.
A [KB][LLM-owned knowledge base] is accessed on demand via grep, not auto-loaded, so changes there are invisible to
sibling sessions.<br/>
To propagate KB-level findings, one must use the indirect path, which involves writing the KB page, then saving a
memory entry pointing to it. The memory save triggers the broadcast, and the recipient can follow the pointer if
interested.

The existing memory-tier scoping provides relevance filtering without any additional mechanism:

- Project memory (`~/.claude/projects/*/memory/MEMORY.md`) broadcasts only to sessions working in the same project.

  This is effectively free real estate. Project memory is the natural home for domain-scoped findings, and the
  propagation is a side effect of the harness watching auto-loaded files. Most session findings belong here.

- [Global memory][giving claude a global memory] (`~/.claude/memory/MEMORY.md`) broadcasts to every active session on
  the machine.

  This requires the finding to be worth placing in the global memory tier. The entry must be relevant **regardless** of
  which repository the recipient is working in. The cost is the semantic commitment of claiming cross-project relevance.

The asymmetry is useful, since the tier selection is itself a relevance filter, and prevents noisy global broadcasts.
Project-level broadcast is nearly free (save a project memory, siblings see it). Global broadcast requires a deliberate
tier choice, which forces the sender to consider whether the finding truly applies everywhere.

In practice, most parallel sessions that would benefit from cross-pollination are working in the same project (or
adjacent projects that share a project memory scope). The cases where a finding in project A urgently matters to project
B are rarer, and the next-session pickup via global memory is usually sufficient for those.

All Claude Code session types receive these notifications.

<details style='padding: 0 0 1rem 1rem'>

Verified on 2026-06-26 using a deterministic marker test.

A background process changed a marker value in the project's `MEMORY.md` from `MARKER-A` to `MARKER-B` after 45 seconds.
Agents of each type read `MARKER-A` on first read, received a system-reminder notification during their file reads, and
read `MARKER-B` on second read.

| Session type                  | Receives notifications? | Verified?        |
| ----------------------------- | ----------------------- | ---------------- |
| Interactive sessions          | **Yes**                 | Yes (2026-06-26) |
| Agent Teams peers             | **Yes**                 | Yes (2026-06-26) |
| Agent tool subagents          | **Yes**                 | Yes (2026-06-26) |
| Agent tool (with Agent Teams) | **Yes**                 | Yes (2026-06-26) |
| Workflow agents               | **Yes**                 | Yes (2026-06-26) |

Traditional subagents were tested with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` disabled to confirm the behavior is not
Agent-Teams-specific.<br/>
Earlier tests with shorter delays (5s, 20s) produced ambiguous results because the modification landed before the
agent's first read.

</details>

The pattern resembles the side effects of the [shadow clone technique] from Naruto. Clones diverge from a shared
starting state, do independent work, and transmit their experience back on dispersal.<br/>
In LLM sessions, each session starts from the same auto-loaded files (divergence), operates in parallel on different
tasks (independent work), and persists findings via memory saves and documentation writes (dispersal). The dispersal is
both **asynchronous** (future sessions read the saved artifacts) and **synchronous** (active siblings receive the
file-watching notification).

The key difference from shadow clones is that **this** dispersal is **selective**. Only knowledge that was saved to
memory (or a KB) propagates. Raw session experience, half-formed hypotheses, and work-in-progress stay local.<br/>
This lossy compression can be a feature if one thinks the effort of writing a coherent memory entry is itself the
quality gate.

The harness injects the **full file content**, not a diff of it. For `MEMORY.md` (~80 entries, ~3k tokens for global at
the time of the experimentation), this is a modest cost per notification that scales linearly with `MEMORY.md` size,
which provides natural back-pressure against excessive entries.

Notifications arrive on the recipient's **next turn**, not instantly. During long autonomous runs, there may be a lag of
several minutes.<br/>
This is arguably a feature; the notification arrives at a natural decision point rather than mid-computation.

When the injected file is long, the system may **truncate** the tail. A new entry appended at the bottom of a long
`MEMORY.md` file could be in the truncated portion, making the notification fire but the content invisible. Keeping the
file concise is the primary mitigation.

**No** filtering happens at the bus level. Every change to a watched file notifies every session that loaded it and that
is it. The recipient session decides wether the change is relevant, the sender cannot.<br/>
This is acceptable because `MEMORY.md` entries are one-liners designed to be scanned quickly, and the two-tier scoping
(global vs project) already provides some coarse filtering.

## Improvements

- Consider a **dedicated broadcast file** to separate "notify siblings now" from "persist for future sessions".

  Using `MEMORY.md` as the broadcast channel mixes the two intents. Every broadcast-worthy finding must be shaped as a
  memory entry, even when it is only relevant to currently-running sessions and has no future-session value.

  The harness watches `@`-included files. A dedicated file (e.g. `~/.claude/broadcast.md`) `@`-included from `CLAUDE.md`
  would be watched and propagated to all active sessions without polluting the memory index.<br/>
  Verified since the global `MEMORY.md` file is `@`-included from `~/.claude/CLAUDE.md` by design, and making changes
  to it does trigger notifications.

  Advantages include:

  - Separation of concerns (memory is for persistence, broadcast is for live notification).
  - The ability to rotate aggressively (only active session findings, pruned at session end).
  - No semantic commitment to the global or project memory tier just to broadcast.

  The two-tier scoping still applies. Project-level `@`-includes notify only siblings working in the project, global
  `@`-includes notify **all** sessions.

- Mitigate **truncation** risk for long `MEMORY.md` files.

  New entries appended at the bottom of a long file risk landing in the truncated portion after injection, making the
  notification fire without the content being visible to the recipient.<br/>
  The primary mitigation is keeping `MEMORY.md` concise. An alternative is structuring the file so that the most
  broadcast-critical entries appear near the top, but this conflicts with the natural append-only pattern.

## Open questions

- Is the file-watching mechanism a stable implementation detail, or could it change without notice?

  The behavior is not documented by Anthropic. It could be tightened (e.g. only watching for external edits, ignoring
  changes made by Claude Code itself) in a future release without being considered a breaking change.

- Does the mechanism survive across Claude Code major version bumps?

  The testing was done against a specific version (mid-2026). The behavior may change as the harness evolves.

- Would a dedicated broadcast file (see _Improvements_) encounter any harness-level limitations?

  The `@`-include mechanism's behavior with frequently-rotating content has not been tested under load.

## Further readings

- [Personal experiments]
- [Giving Claude a global memory]
- [Coordinating sessions across repositories]
- [Claude Code]

### Sources

- [Documentation / Memory]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Claude Code / auto memory]: ../claude%20code.md#auto-memory
[Claude Code]: ../claude%20code.md
[Coordinating sessions across repositories]: cross-project%20sessions.md
[Giving Claude a global memory]: global%20memory.md
[Personal experiments / Memory tiers]: README.md#memory-tiers
[Personal experiments]: README.md
[LLM-owned knowledge base]: llm-owned%20knowledge%20base.md

<!-- Upstream -->
[Documentation / Memory]: https://code.claude.com/docs/en/memory

<!-- Others -->
[Shadow clone technique]: https://naruto.fandom.com/wiki/Shadow_Clone_Technique
