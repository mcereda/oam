---
name: learn-from-experience
description: >-
  Cross-session learning system. Analyzes past session transcripts for
  behavioral patterns (corrections, validated approaches, cooperation
  dynamics), reusable processes (task sequences, ordering and skip
  decisions), notable discoveries, friction, and rule compliance.
  Produces proposed memory updates, CLAUDE.md rule promotions, KB pages
  for reusable procedures, skill instruction updates, and drift reports.
  Use when the user wants to learn from past conversations, extract
  reusable procedures, improve collaboration patterns, or audit behavioral
  consistency. Trigger phrases include: "learn from experience",
  "behavioral review", "learn from past sessions", "session retrospective",
  "what did we learn", "what processes worked", "what mistakes do I keep
  making", "are there patterns in how we work", "let's improve how you
  work with me", "review our collaboration", "what's working and what
  isn't", or any request to analyze, reflect on, or extract patterns from
  previous Claude Code sessions.
model: claude-opus-4-6
effort: xhigh
---

# Learn From Experience

Analyze past session transcripts to find behavioral patterns that span
multiple conversations.

**Quality over quantity.** Partial, honest results are always preferable to
complete, shallow ones. This applies at every step: the extraction agent can
stop mid-transcript if attention degrades, synthesis can skip categories and
return to them, and the final report should be honest about coverage depth.
There is no time pressure on this review.

**Scaling note:** The defaults (`claude-opus-4-6`, `effort: xhigh`) work for
typical workloads. For large batches (>30 sessions), the synthesis step can
exceed the standard context window. Consider using the 1M context model and
`effort: max` before invoking, but be aware that the 1M variant is less
attentive to instructions (e.g. may act on proposals without waiting for
confirmation).

**Arguments:** $ARGUMENTS

Accepted arguments:
- `full` — analyze all sessions (initial retrospective)
- `recent N` — last N sessions by modification time (passes `--recent N` to script)
- `project <fragment>` — scope to a project (e.g. `project claude-kb`)
- (no args) — delta mode: only sessions since last review

**Path note:** Script and output paths are relative to the repo root (the skill's
working directory). The pre-filled context commands for feedback/project memories
derive the project-memory path at runtime via `git rev-parse --show-toplevel | tr '/' '-'`.

## Data contract

### Transcript (input to extraction)

The extraction agent processes one preprocessed transcript at a time:

- **input**: single markdown file path (preprocessed from JSONL transcript)
- **agent dispatch**: one fresh agent per transcript (agent reuse via SendMessage is an unproven optimization; see step 3)
- **preprocessing**: converts raw JSONL to filtered markdown, removing tool results and system messages that don't carry behavioral signal

### Extraction findings (output per transcript)

The agent writes findings to disk at `tmp/learn-from-experience/extractions/<session-id>.md`.
Each file contains a metadata block (for mechanical quality verification) followed by findings in seven categories: corrections, validated approaches, friction, notable discoveries, process patterns, cooperation dynamics, and rule citations.
Each finding cites the session ID and specific turn number(s).

The agent returns a brief completion signal (session ID, findings count, coverage) — findings are on disk, not in the conversation.

Full format specification: `extraction-prompt.md`

An agent may stop partway through a long transcript if attention degrades.
When this happens, it records partial coverage in the metadata block (e.g. "stopped at turn 250 of 400").
Partial coverage is correct behavior, not a failure.

### Review report (output from synthesis)

The synthesis step cross-references all extraction findings against live state (memories, CLAUDE.md rules, KB pages) and produces a structured report with per-category coverage tiers (`S-deep`, `S-spot`, `S-skim`).

Full format specification: Step 5 below.

## Pre-filled context

**Last review state:**
!`cat state.json 2>/dev/null || echo '{"last_run": "never", "reviewed_sessions": []}'`

**Session inventory:**
!`# Replace with your transcript preprocessing script`

**Current feedback memories (for comparison):**
!`command -p grep -h "^description:" ~/.claude/memory/feedback_*.md 2>/dev/null | sed 's/^description: //'`

**Current project memories:**
!`command -p grep -h "^description:" "$HOME/.claude/projects/$(git rev-parse --show-toplevel | tr '/' '-')"/memory/feedback_*.md 2>/dev/null | sed 's/^description: //'`

## Steps

### 1. Select sessions

Based on the arguments and last review state, determine which sessions to
process.

- **Delta (default):** sessions not in `reviewed_sessions` from the state file.
  If the state file says "never", suggest starting with `recent 20` instead
  of processing everything.
- **Full:** all sessions. Warn the user this will take a while.
- **Recent N:** last N sessions by modification time.
- **Project:** filter by path fragment.

Active sessions (detected via `~/.claude/sessions/` registry) are
automatically excluded by `--exclude-active` in step 2, preventing
extraction of incomplete transcripts including this session's own.

Report the count before proceeding. The extraction agent processes
transcripts sequentially (one at a time, ~30-90 seconds each). Wait for
user confirmation if >20 transcripts would be processed — that's 10-30
minutes of sequential extraction plus token spend.

### 2. Preprocess transcripts

Run the extraction script to convert JSONL to filtered markdown:

```bash
# Replace with your transcript preprocessing script
```

Report the list of preprocessed files and their sizes. Each file will be
sent to an extraction agent individually in step 3.

### 3. Extract findings

Spawn a fresh extraction agent per transcript, verify quality on each
output. Two dispatch modes:

**Sequential (default, routine reviews up to ~20 sessions):**
Process one at a time — spawn agent, wait for output, run T1/T2 checks,
then continue. Drift detection runs inline after each extraction.

**Parallel (broad sweeps, 20+ sessions):**
Dispatch all agents concurrently (the harness caps concurrency
automatically). Run T1/T2 checks on all outputs after completion.
Run drift analysis post-hoc over the full set, sorted by extraction
order. Drift detection produces the same signal either way — it
compares each extraction's findings-per-turn ratio against its
neighbors, and disk-first output means ordering doesn't affect quality.

The sequential default exists for operator comfort during routine
reviews: watching quality between extractions catches problems early.
For broad sweeps, the wall-clock cost of sequential dispatch (60-90s
per agent × 100+ sessions = 2-3 hours) outweighs the benefit of early
detection, since T1/T2 checks on disk files are instant regardless of
when they run.

**Implementation notes** (tool-specific, parallel mode):

- **Agent tool**: send all agent calls in a single message for
  concurrency. Drift detection and T1/T2 checks run post-hoc after
  all agents complete (barrier). Do not pass a `model` parameter.
- **Workflow tool**: `Workflow({name: 'learn-from-experience-extract', args: {promptTemplate, transcripts}})`
  where `promptTemplate` is the content of `extraction-prompt.md`
  and `transcripts` is the array of `{sessionId, transcriptPath, outputPath, sizeKb, turnCount}`.
  Uses `pipeline()` with inline drift detection (no barrier between
  extraction and quality check stage). Returns
  `{completed, failed, totalFindings, partialCoverage, driftEvents, results}`.
  T1/T2 shell checks still run post-pipeline in the main session.
  Gives progress tracking via `/workflows`, resume on crash, and
  budget scaling via `budget.remaining()`.
- **Inline fallback**: process all transcripts sequentially in the
  main session.

**For each preprocessed transcript:**

1. Read `extraction-prompt.md`. Fill in placeholders:
   - `{file_path}` — preprocessed transcript path (absolute)
   - `{output_path}` — `tmp/learn-from-experience/extractions/<session-id>.md`
   - `{session_id}` — from preprocessing output
   - `{file_size_kb}` — actual file size (`ls -l` or preprocessing stats;
     agents misestimate this)
   - `{turn_count}` — from the transcript header (`**Turns:** N`)

2. Spawn an agent with the filled prompt. Do not pass a `model` parameter
   (agents inherit from skill frontmatter: `claude-opus-4-6`). Passing
   `model: "opus"` would override to the latest Opus, which may produce
   lower-quality extraction.

3. Wait for completion signal (session ID, findings count, coverage).

4. Run `scripts/verify-extraction.sh <output-file>` for T1/T2 checks.
   In sequential mode, check after each extraction and flag drift inline.
   In parallel mode, batch all checks after completion.

**After all extractions:** run Tier 3 spot-checks (see step 3.5). Report
results before proceeding to synthesis.

**Agent reuse (unproven optimization):** the spec intends agent reuse via
SendMessage to save ~30-40k tokens per spawn. Calibration testing showed
this was unreliable — the agent completed and did not process follow-up
messages. Default to fresh agents. If attempting reuse, send the
follow-up template from `extraction-prompt.md`; fall back to fresh on no
response.

### 3.5. Quality verification

Three tiers applied by the main session after extraction. Tiers 1-2 run
per-transcript (within step 3). Tier 3 runs after all extractions.

**Tier 1 — Structural (mechanical, every transcript):**

Check the extraction output file:
- All 7 category sections present (extra sections like `## Note` tolerated)
- Metadata block with all fields (Project, Transcript turns, Transcript
  size, Findings count, Coverage)
- Each finding cites `[{session-id}]` matching the transcript
- Each finding includes `**Turn:** N` or `**Turns:** N-M`

Implementation: grep section headers and field markers. No LLM judgment.

**Tier 2 — Calibration (mechanical, every transcript):**

- Metadata `Findings count` within 25% of actual count of `- [` prefixed
  lines (agents typically undercount by 6-17%; overcounting also observed)
- Findings-per-turn ratio within plausible range:
  - <3 substantive turns: 0 findings is correct
  - 4-6 turns: 1.5-3.0 findings/turn
  - 10-30 turns: 0.5-1.5 findings/turn
  - 30+ turns: 0.2-1.0 findings/turn
  - Below 0.2 for >10 turns: suspicious under-extraction
  - Above 3.0: suspicious over-extraction
- `Coverage: complete` plausible for transcript length

~20-25% stochastic variation between runs is normal (same prompt, same
transcript, different findings counts).

**Tier 3 — Spot-check (sampled, after all extractions):**

Re-read 1-in-5 preprocessed transcripts and compare against extraction
output. Check for false negatives (obvious findings the agent missed).
If a spot-check finds significant misses, increase the sampling rate.

**Drift detection (after 3+ extractions):**

Track per-extraction: findings-per-turn ratio, output size, citation count.
Compare each against the rolling average of the previous 3.
- Findings-per-turn ratio drops >50% → drift signal
- Citation count drops >40% → drift signal

Use findings-per-turn (actual findings / transcript turn count), not raw
findings count. Raw counts false-positive on mixed-length session sets: a
14-turn session naturally produces fewer findings than a 36-turn session,
but the per-turn rate should be comparable if extraction quality is stable.

On drift: spawn a fresh agent for the next transcript. Optionally
re-extract the flagged transcript and compare.

Note: ~25% variation between consecutive extractions is normal stochastic
variance, not drift. The 50% threshold is set at ~2x the observed natural
variance.

### 4. Synthesize findings

**Read history:** If `findings.jsonl` exists in this skill directory, read it
before starting synthesis. Use historical pattern counts to contextualize
current findings — e.g. "momentum-to-execute: 3 instances (↓ from 5 in
previous review period)" or "api-overconfidence: still appearing despite
rule introduced 2026-06-15." Rule introduction dates come from
`git log --format='%ai %s' -- ~/.claude/memory/ CLAUDE.md` — don't track
them separately.

Read extraction files from disk (`tmp/learn-from-experience/extractions/*.md`).
Cross-reference agent findings against live state — memories, CLAUDE.md
rules, KB pages. Agent analysis fields are preliminary; verify every claim
against current state before accepting it.

**Workflow:**

1. **Triage:** For each finding: act (worth pursuing), skip (already
   covered), or defer (interesting but not actionable now). Agent fields
   provide enough depth to triage without re-reading the transcript.
   Deep-read cited turns only when the agent's analysis seems wrong.

2. **Verify:** For "act" findings, check cited rules and memories still
   exist. Cross-reference against KB pages. When agent analysis disagrees
   with your context, trust your context.

3. **Compile:** Produce the report (step 5). **Two passes minimum.**
   After the first pass, re-read and explicitly ask: "What patterns did
   I miss? Which categories did I skim?"

4. **Chunk** (30+ extractions): Triage in groups of 15-20 files,
   produce intermediate output per chunk, merge in a final pass.
   Verification happens per-chunk.

### 5. Present findings

Report findings in this structure:

```markdown
## Learn From Experience — [date]

### Correction Clusters (rule promotion candidates)
[clustered findings with proposed rules]

### Validated Approaches (memory candidates)
[uncodified patterns with proposed memories]

### Notable Discoveries
[interesting findings with proposed targets: KB page, memory, or "already captured"]

### Cooperation Dynamics
[escalation, scope-expansion, path-commitment, narration-delay, approval-seeking findings;
 trend vs. known patterns in claude-cooperation-dynamics.md; what-worked positive signals]

### Process Patterns (KB/skill candidates)
[reusable sequences with routing: KB page, skill update, project docs, or skip;
 divergences from documented procedures; key ordering/skip/parallel decisions]

### Process Friction (deferred.md candidates)
[clustered friction with structural-vs-environmental test applied;
 proposed deferred entries with trigger conditions]

### Rule Compliance
[gaps, stale memories, confirmations]

### Drift Notes
[observed shifts, if any]

### Stats
- Sessions reviewed: N
- Agents dispatched: N
- Synthesis depth: [S-deep|S-spot|S-skim] per category
- Corrections found: N (clusters: N)
- Validated approaches: N (new memory candidates: N)
- Notable discoveries: N (already captured: N)
- Cooperation dynamics: N (patterns: escalation/scope/path/narration/approval/worked)
- Process patterns: N (reusable: N, skill updates: N, skipped: N)
- Compliance: N violations, N confirmations, N stale
- Friction: N (process friction: N, deferred proposals: N)
- Extraction quality: T1 failures N, T2 flags N, drift events N
- Spot-checks: N/N passed
- Partial coverage: N agents stopped early
```

**Do not apply changes yet.** Present the findings and wait for the user
to decide which to act on. This is a report, not an auto-fix.

### 5.5. Record findings

After presenting the report, append each finding to `findings.jsonl` in
this skill directory (git-tracked, append-only). One line per finding,
using the session's start date (not the review date).

```jsonl
{"date":"2026-06-08","session":"b6a80201","pattern":"design-first","category":"correction","outcome":"already-captured"}
{"date":"2026-07-01","session":"40dec96d","pattern":"api-overconfidence","category":"correction","outcome":"act"}
{"date":"2026-07-01","session":"40dec96d","pattern":"verification-followed","category":"compliance","outcome":"confirmed"}
```

**Schema:**
- `date` — session start date (YYYY-MM-DD); for multi-day sessions, use the start date
- `session` — session ID (short form)
- `pattern` — free-text pattern name; use consistent names across reviews for the same behavior (e.g. always `momentum-to-execute`, not sometimes `premature-action`)
- `category` — one of: `correction`, `validated`, `discovery`, `cooperation`, `process`, `compliance`, `friction`
- `outcome` — one of: `act` (new artifact proposed), `already-captured`, `skip`, `confirmed` (for compliance)

Pattern names are free-text, not enumerated. Let them emerge from the data.
Normalize retroactively if fragmentation becomes a problem.

Record ALL triaged findings, not just actionable ones. "Already-captured"
entries are data points too — they show that the pattern still occurs even
though the rule exists (compliance signal).

**Milestone events:** When a session introduces something significant (a new tool, a CLAUDE.md rewrite, a KB page created from evidence), record it with `category: "event"` and `outcome: "milestone"`. These are context markers for trend analysis, not behavioral findings.

### 6. Apply approved changes

After user review:
- Create/update feedback memories for approved items
- Draft CLAUDE.md rule text for promotion candidates (show diff, wait
  for approval since CLAUDE.md is chezmoi-managed)
- Write approved process-friction entries to `deferred.md` (standard
  format: Deferred date, Revisit-when trigger, evidence sessions) and
  append a `defer` entry to `log.md`.
- Archive stale memories before pruning: append a `retract` entry to the
  KB's `log.md` with the memory's content and the reason it's stale, then
  delete the memory file. The log entry in git history is the archive.
- Mark processed sessions in the state file using explicit IDs:

```bash
# Replace with your transcript preprocessing script
```

  Use `--mark-ids` (not `--mark-reviewed`) to mark exactly the sessions
  that were extracted. `--mark-reviewed` re-runs session selection, which
  can pick different sessions (e.g. agent sessions spawned during
  extraction) and corrupt the state file.

### 7. Log the review

Append to `log.md` if any non-obvious decisions or patterns were found:

```markdown
## [YYYY-MM-DD] learn-from-experience | Cross-session analysis

Reviewed N sessions (delta/full/recent). Key findings: ...
Actions taken: ...
```
