---
name: extraction-triage
description: >-
  Triage the extraction inbox (~/.claude/session-extractions/).
  Scans ALL files, deduplicates items by content, ranks by recurrence, then dispatches triager agents as a team to process batches in parallel.
  Use when the extraction inbox has files to process, the user says "triage extractions", "process the inbox", "check missed saves", "extraction inbox", or at the start of a KB session when a project status file shows pending extraction files.
model: claude-opus-4-6
effort: xhigh
---

# Extraction Triage — Orchestrator

Scan the full extraction inbox, deduplicate, rank, and dispatch for triage.

**Arguments:** $ARGUMENTS

The argument is ignored — this skill always scans the full inbox.

**Scaling note:** The defaults (`claude-opus-4-6`, `effort: xhigh`) work for typical workloads. For large inboxes (>40 unique items after dedup), the synthesis step can exceed the standard context window.

## Architecture

This skill is the **orchestrator**: it handles consolidation (scan, parse, dedup, rank) where seeing all files is essential for recurrence detection.
The per-item work (cross-reference, verify, act/skip/defer) is delegated to triagers, either inline or via dispatched agents.

## Data contract

### Item (input to triage)

Each item extracted from the inbox has:

- **title**: the bold description text
- **context**: explanation after the dash
- **target**: `KB`, `global memory`, `project memory`, or `project docs`
- **qualifier**: `borderline`, `already covered`, etc. (if present)
- **recurrence**: how many extraction files contained this item
- **targetPage**: likely KB page filename (if identifiable), used for grouping to avoid concurrent edits
- **sources**: list of extraction filenames this item appeared in

### Result (output from triage)

Each triaged item returns:

- **title**: matches the input item title
- **action**: `acted`, `skipped`, or `deferred`
- **reason**: one-line explanation
- **target**: where it was written (if acted)

## 1. Scan all files

```bash
ls -1 ~/.claude/session-extractions/*.md
```

If no files exist, tell the user the inbox is empty and stop.

Read every file. Note the total file count and date range.

## 2. Parse items from all files

Each file follows this structure:

```markdown
# Missed saves: YYYY-MM-DD

### <project> (HH:MM) — <session-id>

- **Bold description** — context and reasoning → `target` (qualifier)
```

Extract every bullet item from every file into the item format above.

## 3. Deduplicate and rank

Group items by semantic similarity — same title or clearly the same insight phrased differently across files. For each unique insight:

- **recurrence**: how many files contained it
- **sources**: list of all contributing files
- Keep the richest context version

Sort the deduplicated list:
1. By recurrence count (descending)
2. Within same count, by target: KB > global memory > project memory
3. Within same target, by date (oldest first)

## 4. Dispatch for triage

Group items by targetPage — items likely to edit the same KB page must be processed together to avoid concurrent edit conflicts.

### Inline (≤10 unique items)

Process items directly in this session. For each item:

1. Cross-reference against existing KB pages, memory, and deferred items.
2. Apply triage heuristics (see below).
3. Act (write/update the target), skip (note why), or defer.
4. Record the result.

This avoids agent dispatch overhead for small batches, the typical case when triaging frequently.

### Dispatched (>10 unique items)

Spawn one triager per group. Independent groups (no shared target pages) should run concurrently. Each triager receives its group's items and returns results in the format above.

**This path needs a triager agent definition.** The steps below assume a project-specific agent (called `triager` here) that knows how to cross-reference an item against existing docs/memory, verify claims, and act/skip/defer. Define one before using this path (e.g. as a Claude Code agent at `~/.claude/agents/triager.md`) modeled on the per-item responsibilities described in the Inline section above.

The triager's job: read its agent definition, then process each item (cross-reference, verify claims, act/skip/defer, commit if acting).

Each triager prompt should include:
- The item list with titles, context, targets, and recurrence counts
- The source file list
- "If you don't know or can't verify something, say so."

**Implementation notes** (tool-specific, adapt to what's available):

- **Agent tool**: `subagent_type: "triager"` (use whatever name the agent definition was given), `mode: "auto"`.
  Send all independent agent calls in a single message for concurrency. Do not pass a `model` parameter: agents inherit from the parent.
- **Workflow tool**: `Workflow({name: 'extraction-triage', args: groups})` where `groups` is the array from step 3.
  Uses `parallel()` over groups with `agentType: 'triager'` and schema-validated structured output. Returns `{acted, skipped, deferred, results, failedGroups}`. Gives progress tracking via `/workflows` and resume on crash.
- **Inline fallback**: if neither Agent nor Workflow is available, process all items inline regardless of count.

## 5. Collect results and delete files

After all items are dispositioned, tally results:
- Total acted, skipped, deferred across all groups
- Note any verification findings or push-back from triagers

For each source file: if every item from that file has been dispositioned, delete it:
```bash
rm ~/.claude/session-extractions/YYYY-MM-DD.md
```

Keep files with unprocessed items for the next run.

## 6. Self-monitoring

Check these conditions at the end:

- **Post-dedup item count exceeded 30.** If the inbox regularly produces 30+ unique items, add a per-invocation cap.
- **Skip rate exceeded 80%.** If most items are noise, the extraction hook's signal classification may need recalibration.

If either is true, add a deferred entry to the project's backlog and a brief `defer` entry to the project log.

## 7. Report

Summarize:
- Files scanned and date range
- Raw items → dedup count
- Dispatch method used (inline or dispatched, with agent/workflow)
- Per-group results (acted/skipped/deferred)
- Files deleted vs remaining
- Self-monitoring status

## Triage heuristics (for reference — triagers apply these)

**Verification:** before writing any claim to the KB, follow the verification protocol in the project's contribution guide. Name the source, classify confidence. When no source can be named, mark the claim `[unverified]`.

**Strong save signals:**
- Item in 2+ extraction files (recurrence = genuine gap)
- Non-obvious gotcha or pattern
- Behavioral preference not yet in memory

**Skip signals:**
- Ephemeral project state
- Cached lookup answerable from docs
- Consciously skipped in original session
- Private API surface of internal tools

## Worked example

Inbox: 8 files (May 20-27), 45 raw items.

1. **Scan**: read all 8 files.
2. **Parse**: 45 items extracted.
3. **Dedup**: 18 unique items. 3 with recurrence ≥2.
4. **Dispatch**: >10 items → dispatched. 4 groups by target page. 4 triagers launched concurrently (Agent tool, using the project's `triager` agent type).
5. **Results**: triager-1 (3 acted, 1 skipped, 1 deferred), triager-2 (2 acted, 2 skipped), triager-3 (1 acted, 3 skipped), triager-4 (2 acted, 2 skipped, 1 deferred).
6. **Cleanup**: all items processed → delete all 8 files.
7. **Self-monitoring**: 18 items < 30, skip rate 44% — clean.
8. **Report**: "8 files (May 20-27), 45 raw → 18 unique, dispatched (4 groups), 8 acted, 8 skipped, 2 deferred. Inbox empty."
