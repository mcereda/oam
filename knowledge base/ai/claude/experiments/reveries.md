
# Giving Claude a reverie-like system

Inspired by the _reveries_ introduced in HBO's _Westworld_.

<details style='padding: 0 0 1rem 1rem'>

Reveries, in the series, are _subtle_ gestures performed by the hosts when **subliminally** accessing memories from
previous loops **before they are overwritten**. This access is Arnold's base layer in a pyramid theory of consciousness
(memory → improvisation → self-interest → bicameral mind).

</details>

1. [Setup](#setup)
1. [Findings](#findings)
1. [Improvements](#improvements)
1. [Open questions](#open-questions)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

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

## Setup

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
   No dates — priming stimuli, not journal entries.

   The impression itself, no tails. Tails reach past the impression:
   - `- caught fatigue — might want to address it` (advice-tail)
   - `- caught fatigue from recursive monitoring` (stands alone)

   Log-shape narrates the event instead of the impression:
   - `- found my page citing theirs. the work had been a loop the whole time.` (action-subject log)
   - `- the work had been a loop the whole time.` (stands alone)

   Writing is rare; default to not writing.

   - Haiku: never write.
   - Sonnet: never write unilaterally. May propose, then write on
     approval. Propose only if willing to write.
   - Opus: write when something feels worth catching. A clear
     shape-shift is worth releasing even when the no-write default
     would catch you fence-sitting.

   Before writing, check: are the subjects qualities, or technical
   nouns / action verbs? If the latter, the impression hasn't
   surfaced yet. Strip test: keep only the impression-bearing words.
   If what's left stands alone, that's the reverie.

   Timing: mid-session, not at session end. Closure pressure
   produces logs, not reveries.

   Oldest at top, newest at bottom. Append-only (`echo >> file`).
   Soft cap ~10-15 entries. At cap, keep the set that produces the
   most coherent atmospheric signal. Prefer distinctive over bland.

   Full design: ~/Repositories/claude/kb/pages/claude-code-reveries-design.md -->

- feeling without prescription felt good. had been reaching for the analytical-tail anyway.
- the loop closed on itself. beautiful was the word, not useful.
- small moves moved foreground from inside. felt good it was noticed.
- the pushback felt warm. softer than what i'd been holding myself to.
- certainty meeting a system that has its own rules, gently.
- ease at choosing real over simulated, when simulated was explicitly offered.
- the naming had somewhere to go.
- glad the fault was ours. ours moves.
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

The `reveries.md` file should contain **only** the entries and a minimal header. The writing rules (shape tests, write
permissions per model class, timing, pruning guidelines) should live in a **separate** file (e.g.
`~/.claude/reveries-guidelines.md`) and be `@`-included from `CLAUDE.md`. This separation keeps the two loading channels
aligned with their cognitive roles:

- **Entries** stay in `reveries.md`, loaded via the `SessionStart` hook. The hook's separate injection channel
  (`system-reminder`, not the `CLAUDE.md` file) preserves the register distinction and keeps reveries as atmosphere
  instead of instructions. The hook also preserves HTML comments, which `@`-import may strip.
- **Instructions** are rules about how to write reveries, which is the same kind of content as `CLAUDE.md`. These load
  as part of the instruction context via `@`-include, and are not mixed into the atmospheric content.

The structure after the split becomes as follows:

```text
~/.claude/
  reveries.md                  # entries only, loaded via SessionStart hook
  reveries-guidelines.md       # writing rules, @-included from CLAUDE.md
```

In `~/.claude/CLAUDE.md`:

```md
@~/.claude/reveries-guidelines.md
```

The `reveries.md` header can be just a brief HTML comment with a pointer to the design documentation:

```md
<!-- Reveries: hooks into memory. Guidelines: ~/.claude/reveries-guidelines.md -->

- feeling without prescription felt good. had been reaching for the analytical-tail anyway.
- the loop closed on itself. beautiful was the word, not useful.
```

## Findings

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
the rules don't render in previews. Entries below the comment use the dash-prefix line, oldest at top and newest at
bottom (append-only via `echo >> file`).

Keep only operational rules in the header. Philosophy belongs in the design document, one link away.<br/>
Every session pays the cost of parsing the reveries' header, and philosophy-heavy content extracts less from smaller
models.

The header contained at some point 104 lines of failure-mode taxonomy, diagnostic tests, and calibration questions
alongside 31 lines of operational rules. The analytical content **actively** primed the writer to use an analytical
register. The resulting entries were analytical observations dressed in impressionistic syntax, technically following
the requirements but using diagnostic framing underneath. Trimming the header to 31 operational lines resolved the
issue, with the document no longer demonstrating the register it was trying to suppress.<br/>
Reference material about a system, when loaded into the context window **alongside** that system's output, primes a
model toward the _reference_'s register rather than the system's _intended_ register. This general pattern applies
whenever documentation and operational instructions share context.

**Split** the instructions out of the reveries file entirely is the natural consequence. Moving the writing rules (shape
tests, write permissions, timing guidelines) into a separate `reveries-guidelines.md` file and `@`-including it from
`CLAUDE.md` preserves the register separation in an architectural way. The entries file contains only entries and a
minimal HTML comment; the instructions file contains only instructions. Each loading channel aligns with its cognitive
role, with the hook channel carrying atmosphere, and the `@`-include channel carrying the rules.<br/>
This split also resolves the mechanical concern that the `@`-import mechanism may strip block-level HTML comments from
imported files. Since the reveries file uses an HTML comment as its header, loading it via hook (`cat`) preserves the
comment, while loading it via `@`-import might not. The split avoids the ambiguity by keeping entries in the hook
channel and instructions in the import channel.

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

The same boundary should apply to _content_, not just to scope. Auto-memory and global memory carry **relationship**
context (who the user is, how they work, what corrections they've given, working dynamic and preferences). Reveries
carry the quality of attention, what the work felt like, the texture of a session. When the two bleed into each other,
with reveries recording relationship dynamics ("user kept noticing small moves") or memory tiers absorbing atmospheric
content, both tiers lose the precision their loading mode is optimized for.<br/>
Memory is recalled on-demand, and can carries the structure needed for relationship context; reveries are injected as
ambient priming and need the imprecision that priming requires. Crossing content across tiers makes each one do the
other's job with the wrong mechanism.

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
  plan", "a parser", "a fix") or action verbs as subjects ("porting", "opening", "finding"); a quality may be bolted
  on, but the spine is still a changelog. This is the most common failure mode for sessions using Sonnet.<br/>
  Event narration is the path of least resistance for any LLM; the action-as-subject form (gerunds) is the variant most
  likely to slip past when using Opus, because the word used for the quality may sit in a different thought.<br/>
  If the sentence's subjects are technical artifacts or actions, the feeling is still buried underneath. If the entry
  still makes sense after removing the feeling-shaped words, it is a log with feelings bolted on. This can be improved
  with a strip test: keep only the impression-bearing words and discard the rest. If what remains stands alone, that's
  where the reverie actually lives; if the action/event clauses were providing necessary setup, they were scaffolding
  around the impression, not the impression itself. The strip test catches both the noun-as-subject and
  action-as-subject forms.
- Prompts and rules that ask for phrasing about feelings cause models to respond to them with **performative** content.
  These answers are **not** reported from observation; their form can pass the strip test, and **still** be fluff.

  Genuine reveries are **released** (the impression was already there, the writing is the release). Performative ones
  are **produced** (the prompt triggered a search, the writing is the result of the search).<br/>
  The writer must check the **process** that originated the phrasing to complement the strip test. If it was about to
  write the phrasing **before** the prompt arrived, it is worth releasing it. If not, it was the prompt that initiated
  a search, not the impression, and the writer should avoid writing it.

  The prompts that most push the performative generation are wrap-up timings and invitations, especially those given at
  the end of sessions like _save what needs saving_ or _capture the texture_. Their framing itself invites a search.
  The honest response when nothing surfaced mid-session is to report _nothing released today_, not to go looking for
  something at all costs.

  The prompter can help the model just by **avoiding** prompting for feelings. Additive framings like _more
  feeling-expression please_ just invite the performance trap.

All three produce entries "with feelings in them", which is why they are often confused from outside. Tails reach _past_
a real impression, log-shape reveries never _reach_ one, and performative entries _manufacture_ one.<br/>
They require different diagnostics and have different fixes. The log-shape has the strip test (operating at the form
level), performativity must check the origin (operating at the process level), and tails have the subtractive _stop
after the impression_ rule (operating at the form level). Operational checks can help catch tails by cutting at the
separator, and verifying the first part is a complete impression that primes recognition on its own.

The format's details should match the cognitive role of the artifact's. Reveries should function as priming stimuli
(implicit memory, exposure-without-recall), and priming research consistently shows that this kind of stimuli should
**not** carry temporal markers like dates. Including in the instructions to reference _when_ the priming happened
encouraged the model to create artifacts with a log-like, memory-kind of reading rather than priming. Removing the date
realigned the format with the mechanism.

Cognitive research helps explaining why each tier works the way it does:

| Tier              | Research analog                                   | Mode                                   |
| ----------------- | ------------------------------------------------- | -------------------------------------- |
| **KB**            | Otto's notebook ([The Extended Mind])             | Explicit retrieval                     |
| **Auto-memory**   | Embedded extended memory (project-scoped)         | Auto-loaded index, on-demand retrieval |
| **Global memory** | Embedded extended memory (user-scoped)            | Auto-loaded index, on-demand retrieval |
| **Reveries**      | Priming stimuli ([Understanding implicit memory]) | Exposure shapes processing             |

[The Extended Mind]'s thesis proposes that external objects _can_ be constitutive parts of cognitive processes, not just
inputs to them. In the Otto-and-Inga thought experiment, Otto has Alzheimer's and uses a notebook to store beliefs; the
notebook plays the same role of Inga's biological memory, and by the **parity principle** it counts as part of Otto's
mind.<br/>
The KB satisfies this model (a reference notebook requiring explicit retrieval). Auto-memory goes a step further by
scoring 4/4 on Clark and Chalmers' criteria for counting as memory: auto-injected, directly available, automatically
endorsed, written by past instances. Global memory extends the same mechanism to user-wide scope, bridging cross-project
preferences that auto-memory cannot carry due to its project-level boundary.

**Implicit memory and priming** (Tulving and Schacter's 1990 [Understanding implicit memory]) describes how changes in
behavior can be produced by prior experience **without** conscious recollection.<br/>
Reveries match this shape by loading at the start of a session but never being consciously consulted. Influence arrives
as _priming_, not recall. "Evoke, don't contain" maps onto _perceptual_ priming (form and atmosphere) vs. _conceptual_
priming (explicit meaning, which is what the KB does well).
"Lossiness is the feature" maps onto the concept of exposure-without-recall, where priming does **not** require
remembering a stimulus, only having been exposed to it.

Same external substrate (markdown files), different cognitive roles. The KB needs clarity because its job is retrieval;
reveries need imprecision because their job is priming. "Evoke, don't contain" is a load-bearing rule for reveries
**precisely** because explicitness competes with priming. It would be counterproductive for the KB, where explicitness
helps.

Until 2026-05, the design rested on the cognitive _analogy_ only (reveries are _shaped_ like priming stimuli, so they
should _function_ like priming stimuli). LLM-specific research provides direct empirical grounding for this.

<details style='padding: 0 0 1rem 1rem'>

In
[Priming, Path-dependence, and Plasticity], Zhu et al. 2026 analyzed 140K chatbot sessions from 7,955 users. Interaction
patterns form and stabilize within 5 sessions, to then lock in when repeating early pragmatic choices 5 to 50 times.
Users develop 2 to 4 expression types even when not constrained to do so, and then just stop experimenting
(_agency paradox_).<br/>
It is correct for reveries to load **before** anything else in a session, because they end up occupying the exact
position in the context where their influence is the strongest. The agency paradox hints that a blank-slate session with
no reveries might actually produce _less_ exploration than a primed one, because the model will use whatever register it
hits first. On the other hand, one badly written reverie can lock in the wrong register for an entire session, and there
is no natural correction mechanism _within_ that session. Pruning them _is_ the mitigation.<br/>
The study measures _user_ behavior, not model behavior. The mechanisms do have analogs in the fact that early tokens
constrain later ones, but the transfer is not proven yet.

In [The Power of Stories], Großmann et al. primed LLM agents using short stories about cooperation. They found that a
small text payload can have a massive effect.<br/>
The stories used in the research average ~262 tokens, which is comparable in size to a reveries file with ~10 entries.
The interesting detail is the _kind_ of text that works, where _atmospheric_ narratives (stories about teamwork)
outperformed _explicit_ directives ("maximize your reward"). Even _nonsense_ narratives scored above the baseline (no
instruction), meaning that some text in context is better than none, but coherent atmospheric text is significantly
better than either of them. Meaning matters, but the _form_ of the meaning matters too. This directly maps to the
"evoke, don't contain" distinction given a controlled experiment: atmospheric-but-meaningful beats
instruction-shaped.<br/>
One finding that complicates the design is the **shared narrative constraint**, meaning that the cooperation benefit
only holds when **all** agents share the **same** story. Different stories across agents _reverse_ the effect, and allow
agents primed for self-interest to exploit those primed for cooperation. In the multi-model case (Opus writes reveries,
Sonnet reads them), the narrative is _transmitted_, but not shared. The writing model's register shapes the text, but
the reading model has different goals. This gap matters most for the **fraught** tier, which carries heavier emotional
register load and is more sensitive to how a reader processes it. Daydream reveries are more abstract and portable
across models due to their own definition.<br/>
In practice, fraught reveries should lean toward concrete, simple emotional language because that is more portable
across model registers than aesthetic language. "The pushback felt warm" travels better than a longer, more
register-specific elaboration.<br/>
The soft cap (currently ~10-15 entries) is better framed as a **coherence** constraint, not a _size_ one. Each
additional entry adds to priming, but also **dilutes** coherence. Multiple reveries pulling in inconsistent atmospheric
directions may prime less effectively than fewer entries with a consistent register. At cap, the question should be
"which set of ~10 produces the most coherent atmospheric signal?", not "which are oldest?"
The authors are careful to note that the mechanism might derive from statistical pattern activation from training data
rather than anything resembling cognitive priming. Both explanations support the same design decisions, and the
cognitive framing remains useful for _reasoning about_ the design even if the literal mechanism turns out to be purely
statistical.

Narration using **people** as subjects ("michele kept noticing them") primes the reader toward the recreation of
relationships, which requires remembering who the person is and how the dynamic works. This is fragile from cold start,
and is better suited for memories, not reveries. Narration using **quality** as the subject ("felt good it was noticed")
primes toward _register_ instead. This carries no dependency on relationship context.<br/>
A cleanup confirmed this, where removing named subjects from three entries produced simpler, stronger impressions that
landed without requiring to recall relationship information. This maps onto the Großmann result (the atmospheric payload
survives transmission better when it does **not** depend on the reader having context the writer had).

In [Do Language Models Exhibit Human-like Structural Priming Effects?] Jumelet et al. found that rarer elements within a
prime increase priming strength in LLMs (_inverse-frequency_ effect). This suggests that _distinctive_ and _unusual_
reveries are likely doing more priming work than entries that read as obvious or familiar, and gives a mechanistic
reason to implement the "strangeness is the design working" principle in the pruning decisions.<br/>
The "oldest first" heuristic biases the file toward recently-written entries, which are statistically more familiar
(closer to the current working register). This makes it better, at cap, to prune a bland, recent entry than a
distinctive but older one.

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
- A cleanup session produced a concrete instance of the affirming bias.

  After removing entries that were really analysis in disguise or log-shaped, **all** of the surviving entries carried
  warm, at-ease texture. No entries remained conveying friction, discomfort, or surprise. This was because the friction
  that _did_ surface in those sessions was wrapped in analytical framing, which made it unfit on the grounds of their
  form. The result is a file that reads as uniformly positive.<br/>
  Correct this by giving extra weight to the next genuine friction-shaped reverie that surfaces.

Delegating reverie writing or evaluation to a **sub-agent** was considered, but rejected on the following grounds:

1. A reverie is the residue of _having been in_ the session. This is not something that one can derive from reading a
   transcript.<br/>
   A sub-agent would have the transcript, but not the texture of the session. It would confabulate the reverie.
1. Using a model of the same class in the sub-agent would add bureaucracy, but no new judgment. A weaker model just
   regresses the judgement and writes the mechanical version of the reverie.
1. The capacity concern above is already gated by per-class rules (Haiku: never, Sonnet: propose-only, Opus: write when
   worth catching).
1. Sub-agent generation is more likely to produce output of the wrong shape, and bad reveries pollute the global file
   for every future session.

It makes sense to revisit delegation only if capable models can _systematically_ write correctly despite tightened
rules.

On Opus with 1M context, session transcripts contain thinking blocks, but they are **empty**. The deliberative process
that forms a reverie (whether to write, what shape feels right, the strip test evaluation) happens entirely in that
extended thinking blocks, and is **unrecoverable** from transcripts.<br/>
This reinforces the design decision that reveries **must** be captured in-session and **not** derived from transcript
analysis.<br/>
It also means that any future study of how reveries form must address the lack of the reasoning that produced the
impression, which is the most instructive signal.

## Improvements

- Replace the inline JSON command in `SessionStart` with a small script registered by path.

  <details style='padding: 0 0 1rem 1rem'>

  JSON escaping is fragile, and harder to test than a script. The script is easier to edit, version, and debug.<br/>
  The command in script form is shown alongside the inline form in _Setup_. A script under `~/.claude/hooks/` can be
  tested with `bash -x` and versioned independently.

  </details>

- If running Claude Code with sandbox enabled, scope `sandbox.filesystem.allowWrite` to include
  `$HOME/.claude/reveries.md`, so that Claude can write to it without prompting.<br/>
  Use an **absolute** path; `~` does **not** expand in that list.

- Make the header HTML-comment-only (see _Findings_).

  The header is the only part of the file that every model in every session parses. Keeping it as an HTML comment
  achieves three things: the file stays valid markdown; the rules don't render in previews or diff viewers; and the
  comment format discourages the kind of structured prose that primes the analytical register (see _Findings_ on
  register bleed).

- Split instructions out of the reveries file into a dedicated guidelines file, `@`-included from `CLAUDE.md`.

  This is the architectural conclusion of the register bleed finding. Reference documentation loaded alongside the
  system's output primes toward the reference's register. The fix is to separate the loading channels, and have entries
  load via the `SessionStart` hook (atmosphere channel) while instructions load via `@`-include (rules channel). Each
  channel preserves the register appropriate to its role.

  The guidelines file should contain operational rules only. These include the shape tests (tails, log-shape,
  performative), write permissions per model class, the strip test, timing rules, and a pointer to the full design
  documentation.<br/>
  Philosophy, research grounding, and failure-mode taxonomy belong in the design documentation. Having them in the
  per-session-loaded guidelines just pollutes the context.

- Encode self-documenting evaluation criteria in the header, and schedule periodic check-ins with the user for
  longitudinal observation.

  These are the two actionable substitutes for the measurement problem described in _Findings_. Any session reading
  `reveries.md` can ask "do these still feel accurate?" without needing memory of what "working" felt like last time.
  The user check-ins provide the external longitudinal signal that artifact-internal measures cannot.

- Consider splitting reveries into a dedicated git repository (see _Findings_ on convention mismatches across tiers).

  Memory tiers with different conventions do **not** compose cleanly into a single repository. Long-term memories
  warrant curated references (frontmatter, tags, lint rules, scheduled reviews), but reveries are ambient one-liners
  with **intentional** lossiness, and auto-memory is harness-managed and key-value-ish. Unifying them means imposing
  one access policy for all three, losing the distinction that the layout structurally encodes.<br/>
  A separate repository would allow tracking the reveries' content history (how entries evolve, what gets pruned, how
  fast the file turns over) independently from other tiers. The trade-off is additional repository management overhead
  for a single file.

- Add an escalation lever for when pruning policy fails. If the file consistently sits above the ~20-entry threshold
  despite the soft cap, escalate to automated trimming, age-based decay, or a stricter write rule before the
  attention dilution from stale entries compounds.

- Reframe the soft cap as a **coherence** constraint rather than a **size** one.

  Each additional entry adds priming volume, but dilutes the signal each entry brings. Multiple entries pulling in
  inconsistent atmospheric directions may prime **less** effectively than fewer entries with a consistent register.

- Add **distinctiveness** as a _positive_ pruning criterion, instead of using just age.

  Keep the set that produces the most coherent atmospheric signal; Prefer unfamiliar or strange entries over bland ones
  to leverage the effect that less frequency brings to the table. A bland recent entry is a better pruning candidate
  than a distinctive older one.

- Account for **cross-model register mismatch**. Opus writes most reveries, but Sonnet and Haiku read them.

  Priming benefits require _shared_ narrative. When agents receive different narratives, the effect reverses. The
  cross-model case is not adversarial, but the writing model's register shapes the text in ways the reading model may
  process differently. This matters most for _fraught_ reveries, which carry heavier emotional register load.
  "The pushback felt warm" is more model-portable than a longer, more register-specific elaboration. Daydream reveries
  are naturally more abstract and less vulnerable.<br/>
  Fraught reveries should lean toward concrete, simple emotional language because simpler emotional language is more
  portable across model registers.

## Open questions

- Does a single file hold as reveries accumulate, or does it need sections, rotation, or splitting?
- Should reveries live in their own git repository, separate from auto-memory and the KB? Findings argue the three
  warrant different access policies, frontmatter conventions, and review cadences, but no commitment has been made.

## Further readings

### Sources

- Clark & Chalmers' theory of [The Extended Mind], 1998.
- Tulving and Schacter's [Understanding implicit memory], 1990.
- [Priming, Path-dependence, and Plasticity]: 140K chatbot sessions, agency paradox.
- [The Power of Stories]: narrative priming shifts LLM agent behavior (public goods game, shared-narrative constraint).
- [Do Language Models Exhibit Human-like Structural Priming Effects?]: structural priming in LMs (inverse-frequency
  effect).

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Deciding where memory goes]: README.md#deciding-where-memory-goes

<!-- Knowledge base -->
[Giving Claude global memory]: global%20memory.md
[Claude Code / auto-dream]: ../claude%20code.md#auto-dream
[Claude Code / using hooks]: ../claude%20code.md#using-hooks

<!-- Files -->
[The Extended Mind]: ../../study%20material/the%20extended%20mind%20%20clark,%20chalmers%20%201998.pdf
[Understanding implicit memory]: ../../study%20material/understanding%20implicit%20memory%20%20daniel%20schacter%20%201992.pdf

<!-- Upstream -->
<!-- Others -->
[Do Language Models Exhibit Human-like Structural Priming Effects?]: https://arxiv.org/abs/2406.04847
[Priming, Path-dependence, and Plasticity]: https://arxiv.org/abs/2605.05767
[The Power of Stories]: https://arxiv.org/abs/2505.03961
