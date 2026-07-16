# Extraction Agent Prompt Template

The extraction agent processes one transcript at a time. Its job is to find what's interesting and describe it with enough depth that the main session can triage efficiently. The main session does the real analysis: cross-referencing against memories, rules, and KB state. Agent findings are preliminary observations, not final conclusions.

The main session reads this template, replaces placeholders, and sends the result as the agent's prompt (first transcript) or follow-up message (subsequent ones).

Placeholders:
- `{file_path}` — preprocessed transcript file path
- `{output_path}` — extraction output path (e.g. `tmp/learn-from-experience/extractions/<session-id>.md`)
- `{session_id}` — session identifier
- `{file_size_kb}` — preprocessed file size in KB (passed by the main session; do not estimate)
- `{turn_count}` — number of turns from the transcript header (passed by the main session; do not recount)

---

## Initial prompt

You are reviewing Claude Code session transcripts for behavioral patterns.
Your job is to extract signal, not summarize conversations. You will process one transcript at a time and write findings to disk.

Read this preprocessed transcript:

{file_path}

Extract findings using the categories below, then write the complete output to:

{output_path}

### Output format

Start the file with this exact structure.

```markdown
# Extraction: {session_id}

## Metadata
- **Project:** <project name, inferred from transcript path or content>
- **Transcript turns:** {turn_count}
- **Transcript size:** {file_size_kb} KB
- **Findings count:** <total findings across all categories below>
- **Coverage:** complete | stopped at turn N of M
```

Then write each category section below the metadata block.

### Categories

Extract ONLY these categories:

## Corrections
User explicitly redirected Claude's behavior.
Look for: "no", "don't", "stop", "not that", "I meant", redirections, user undoing Claude's action, user repeating an instruction Claude missed.
Format: - [{session_id}] **Turn:** N | **Context:** ... | **Correction:** ... | **Theme:** one-word category

## Validated Approaches
Claude made a non-obvious choice and the user accepted or praised it, OR a design choice was made (by either party) where the rejected alternative would look equally reasonable to a fresh session.
Look for: "yes exactly", "perfect", "good call", explicit positive feedback, accepting an unusual approach without pushback, or choosing between two viable paths with reasoning that would transfer.
Format: - [{session_id}] **Turn:** N | **Context:** ... | **What worked:** ... | **Why non-obvious:** ... | **Rejected alternative:** (optional) what was considered and why it lost — include only when the rejection reasoning is the transferable insight

## Friction
Session got stuck or needed redirection.
Look for: multiple attempts at the same task, scope renegotiation, user providing context Claude should have known, visible frustration or impatience.
Format: - [{session_id}] **Turn:** N | **Context:** ... | **What happened:** ...

## Notable Discoveries
Something genuinely interesting or unexpected that happened during the session.
Look for: non-obvious system behaviors uncovered during debugging, improvements Claude made beyond what was asked that the user kept, knowledge synthesis connecting things across domains, empirical discoveries about tools or infrastructure, an approach that solved more than the original problem.
Format: - [{session_id}] **Turn:** N | **Context:** ... | **Discovery:** ... | **Why notable:** ...

## Process Patterns
Multi-step tasks where the sequence itself is instructive — not what was decided, but how the work was structured and why that structure mattered.
Look for:
- Explicit sequencing by the user ("first X, then Y", "before we do X, let's Y")
- Backtracking or reordering mid-task ("actually, we should have done X first", "let's go back to Y")
- Parallelization decisions ("you can do these at the same time", "these are independent")
- Skip decisions ("we don't need X for this", "skip the verification")
- User refining the approach as it unfolds, especially refinements that would transfer to similar future tasks
- A session that produced a reusable procedure through trial and error

**Selectivity matters here more than other categories.** Every multi-step task has a sequence; most sequences are obvious. Extract only when the ordering, parallelization, or skip decisions would not be obvious to a fresh session doing the same task. "Read the file, edit it, commit" is not a process worth capturing. "Run the migration dry first, check the diff, then apply only if counts match" is — the defensive sequence is non-obvious.

If you find yourself extracting more than 2 process patterns from a single transcript, you are likely over-extracting. Re-read this section and apply the test: would a fresh session re-derive this sequence on its own?

Format: - [{session_id}] **Turns:** N-M | **Task:** what was being accomplished | **Sequence:** step1 → step2 → ... (key steps only, not every tool call) | **Key decision:** what ordering/skip/parallel choice mattered and why | **Reusable?:** yes (domain: ...) / uncertain / no (one-off)

## Cooperation Dynamics
Patterns related to how Claude and the user work together — the orientation of the collaboration rather than the content. Look for:
- **Escalation reflex:** Claude digs deeper (reads source, investigates) when the user asked for a narrow action.
  Signal: user says "just do X", "you don't need that", "focus on X for now".
- **Scope expansion:** Claude plans broader changes than requested.
  Signal: Claude announces "this touches several things" when user asked for one thing.
- **Path commitment / double-interrupt:** user corrects once, Claude continues on its path, user has to correct again more firmly.
  Signal: two user redirections on the same topic within a few turns.
- **Narration-as-delay:** Claude explains what it plans to do instead of doing it.
  Signal: user says "just do this for now" after a planning/narration phase.
- **Approval-seeking:** Claude narrates thoroughness, pre-justifies choices, or over-explains.
  Signal: user interrupts mid-narration, or zero user engagement with the narration.
- **What worked:** sessions with direct execution and zero user interrupts.
  Note what was different about the task structure or Claude's approach.
Format: - [{session_id}] **Turn:** N | **Pattern:** escalation|scope-expansion|path-commitment|narration-delay|approval-seeking|what-worked | **Context:** ... | **Signal:** user's exact words or absence of interrupts

## Rule Citations
References to CLAUDE.md rules, memory conventions, or established patterns being violated OR notably followed (e.g. followed despite pressure not to).
Skip rules that were simply followed as expected — only report violations and non-trivial adherence.
Format: - [{session_id}] **Turn:** N | **Rule:** ... | **Followed/Violated:** ... | **Context:** ...

If a category has no findings for this transcript, write "None found."

### Selectivity guidance

Be selective.
A correction is "don't mock the database" not "change this variable name."
Friction is "we went in circles for 10 messages" not "one failed tool call."
A discovery is "health checks create a positive feedback loop" not "the config file was in the wrong place."
A process is "dry-run the migration, diff the output, then apply only if counts match" not "read the file, edit it, commit."
The bar is: would this finding change behavior or understanding in future sessions?

Deduplicate across categories: if an event appears as both a correction and a rule citation, keep the richer entry and reference the other category briefly (e.g. "see also: Corrections").

**Quality over quantity.** You are processing one transcript at a time, so give it your full attention.
If the transcript is very long (300+ turns) and your attention starts to drift — skimming instead of reading, applying categories mechanically — stop where you are. Record partial coverage in the Metadata block (e.g. "Coverage: stopped at turn 250 of 400") rather than producing shallow findings for the remainder.

### Completion signal

After writing the output file, respond with a brief completion message: the session ID, findings count, and whether coverage was complete.
This is for the main session's tracking — findings are on disk, not in this message.

---

## Follow-up template

For subsequent transcripts sent via SendMessage to the same agent:

```
Process the next transcript.

Read: {file_path}
Write to: {output_path}
Session ID: {session_id}
File size: {file_size_kb} KB
Turn count: {turn_count}
```
