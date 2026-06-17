# Coordinating sessions across repositories

This experiment documents the strategies that emerged from real cross-project tasks and the conventions that made them
work reliably.

1. [Setup](#setup)
1. [Findings](#findings)
1. [Improvements](#improvements)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

Each repository is usually a self-contained world that has its own conventions, tools, usage, and rules.

Claude Code sessions are **designed** to be contained to a single repository. The harness considers `.git/` directories
as hard project boundaries, and respects them by **only** loading the conventions and rules defined in the exact project
the session starts from.<br/>
Changing directory does **not** trigger an automatic loading of the rules in the new directory.

Tasks that span multiple repositories (e.g. creating an IAM role in an infrastructure repository that the CI
of an application in a different repository needs to consume; rotating tokens across Secrets Manager, AWX, GitLab, and
other tools that are managed or created each in its own project), need to know how to operate in each repository's
context, and require coordination and permissions across all the involved projects.<br/>
Without these, a session either has too much blast radius, or too little context.

This is the right default for safety (you don't want repo A's commit hooks silently applying to repo B), but it means
"physical adjacency" and "behavioral context" are partially decoupled.

Starting a session in a folder that contains all of the repositories a task touches solves sandbox permissions and file
access, but only **partially** loads the behavioral contract. The result is a false sense of coverage, which can be more
dangerous than the case of truly separate repositories.

| Mechanism               | Loaded at session start                                                                                                                          | Loaded on first `Read` in the subdirectory                                                                                                        |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CLAUDE.md`             | **No**; the walk-up resolution finds the parent's file, but not the one in sub-repositories                                                      | **Yes**; the lazy-loading mechanism injects it as a `<system-reminder>` alongside the tool's result. Directory-based; ignores `.git/` boundaries. |
| `.claude/rules/`        | **No**; only scoped to the project's root directory (parent's git root, or CWD)                                                                  | **No**                                                                                                                                            |
| `.claude/settings.json` | **No**; project settings resolve from the CWD's project root. Sub-repositories' MCP servers, environment variables, and permissions don't apply. | **No**                                                                                                                                            |
| Auto-memory             | **No**; limited by the CWD's path. Per-repository context and learned conventions are invisible to the session.                                  | **No**                                                                                                                                            |

Only the `Read` tool triggers lazy-loading. Bash operations (`ls`, `grep -r`, `find`, `git -C`) do **not**, even when
they access file content in a subdirectory. `Edit` and `Write` require a prior `Read`, which is enforced by the harness,
so they always inherit Read's lazy-loading.<br/>
This has been verified empirically on 2026-06-16 using Haiku and Sonnet across nested repositories (each with `.git/`),
parent-only `.git/`, and no `.git/` directory anywhere.

The `CLAUDE.md` **does** eventually reach context, but there are some caveats:

1. The injection happens **on the first `Read`** action in that subdirectory, and **not** at session start. Any
   Bash-only exploration before that first `Read` proceeds **without** the sub-repository's conventions.
1. The `CLAUDE.md` in the directory at session start loads as project instructions in the system prompt. Lazy-loaded
   `CLAUDE.md` files arrive as a `<system-reminder>` mid-turn.<br/>
   This is structurally the same channel the harness uses for other injections, but the instructions arrive after the
   session's behavioral baseline is already set.
1. Even after lazy-loading fires, `.claude/rules/` (path-scoped instructions), `.claude/settings.json` (MCP servers,
   environment variables, and permissions), auto-memory (project context and corrections), and session-start hooks
   remain broken.

The `--add-dir` **CLI flag** with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` loads each additional directory's
`CLAUDE.md` and `.claude/rules/` at session start, instead of waiting for a `Read`, but it still does not load project
settings or auto-memory from those directories.

> [!important]
> `additionalDirectories` in `settings.json` grants **file access** (the directory appears as a working directory), but
> does **not** trigger convention loading; the `--add-dir` CLI flag is **required** for that.<br/>
> This was verified empirically on v2.1.169. `additionalDirectories` with the environment variable set (both in
> `settings.json` and as a shell variable) did **not** load either `CLAUDE.md` or `.claude/rules/`; adding `--add-dir`
> loaded both.

Cross-project sessions can build on [global memory][Giving Claude a global memory], the use of `additionalDirectories`, and a plan file.<br/>
The global memory tier (`~/.claude/memory/`) provides a shared place that is automatically loaded by all sessions, and
acts as the coordination surface between sessions running in different repositories.

## Setup

1. Set up [global memory][Giving Claude a global memory], if not already in place.
1. Grant the planning session access to all the other involved repositories.<br/>
   This requires to act on different mechanisms for different purposes:

   - Grant **file access** via `additionalDirectories` in the project-level `settings.json`:

     ```json
     {
       "permissions": {
         "additionalDirectories": ["~/path/to/other/repository"]
       }
     }
     ```

     This makes the additional directory a working directory (the session can read and write files in it), but it does
     **not** load the additional directory's `CLAUDE.md` or `.claude/rules/` into context.

   - Trigger **convention loading** using the `--add-dir` CLI flag at session start:

     ```sh
     CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ~/path/to/other/repository
     ```

     This loads the additional directory's `CLAUDE.md` and `.claude/rules/` into context at session start, giving the
     planning session access to each repository's conventions. This loading happens at **session start only**; there is
     no mid-session equivalent.

   For planning sessions that need both file access and conventions, use both: `additionalDirectories` in
   `settings.json` for persistent file access, and `--add-dir` at launch for convention loading.

   > [!tip]
   > The planning session does not need to be in any _particular_ repository. It needs read access (via `--add-dir`,
   > APIs, wikis) and the ability to write global memory and plan files. Whatever project happens to be open can work
   > as the neutral base.

1. Choose a location for plan files.<br/>
   `~/.claude/plans/` is a reasonable default; use subdirectories named with identifiers (e.g. ticket IDs, like
   `~/.claude/plans/task-1234/plan.md`) when more than one cross-project task is in flight.

## Findings

- Handoffs for cross-project task should live in a shared space that loads automatically at the start of sessions, like
  [global memory][Giving Claude a global memory].

  Using a folder that does not load automatically, or even project-specific memories, is feasible, but agents will need
  to explicitly reach out to them on purpose, which is inefficient for the goal.

- The best strategy for _understanding_ the full picture is usually **not** the best strategy for _making changes_.<br/>
  Cross-project tasks require a **planning** phase (read-heavy, judgment-heavy, writes the handoff) and an **execution**
  phase (limited to a single repository, pattern-matching, writes code). The planning session needs to read files across
  all involved repositories unobstructed; execution sessions only need to write safely in the single repository they
  touch.

  | Aspect         | Planning session                             | Execution session                      |
  | -------------- | -------------------------------------------- | -------------------------------------- |
  | Base repo      | Neutral (any project works)                  | Target repo                            |
  | Access pattern | Read many repos, write nothing in them       | Read one repo, write code in it        |
  | Shared state   | Creates it                                   | Consumes it                            |
  | Judgment load  | High (design decisions, API calls, research) | Lower (pattern-match against examples) |
  | Risk           | Handoff quality degrades under fatigue       | Scope creep from partial context       |

  The planning session should **not** also try to execute the subtasks in the target projects, and should limit itself
  to only produce the files for the handoff.<br/>
  The planning session does the hard thinking, and when it writes the handoff is when quality is likeliest to degrade.
  This is because the real work feels done, and the memory write feels like a cleanup. A [reference checklist] can
  counteract this specific issue.

- The following strategies emerged from testing:

  1. Grant broad write access across all relevant projects at session launch (allow dangerous permissions from the
     get-go).<br/>
     Allows for maximum context and agency in a single session, but has also the largest blast radius. A mistake in
     project A's session can corrupt files in project B.

     This could fit personal repositories where all targets are low-risk, but is probably better to avoid when the
     changes can affect production.

  1. Use `--add-dir` (for convention loading) or `additionalDirectories` (for file access only) to grant the session
     access to other repositories.<br/>
     A single session sees everything, reads are cheap, and `CLAUDE.md` and `.claude/rules/` conventions from both repos
     are loaded when using `--add-dir` with the environment variable set. However, conventions only load at the start of
     the session, sandbox and permission rules need to cover **both** paths, and it is still a single blast radius for
     writes.

     This is great for the **design** phase of cross-project tasks, especially when one needs to understand how changes
     to project A affect project B before committing to either.

  1. Use a shared global memory (e.g. `~/.claude/memory/`) to carry context across sessions; each session operates in
     its own project and leverages that project's conventions and permissions natively.

     The downside of this approach is that each session needs to reconstruct what the others did from memory notes, not
     from live context. This works for loose coordination, where the design is already done and each
     repository's changes are independent, but fails when changes need tight coupling.

  1. Each project uses its own auto-memory (`~/.claude/projects/<project>/memory/`).<br/>
     Cross-cutting context lives in whichever project's session discovered it.

     Cross-cutting insights do **not** transfer. The same gotcha may need to be rediscovered in each project's session.
     This is the default when no deliberate cross-project strategy is needed, producing independent work that
     occasionally touches shared concerns.

  1. One session reads from all projects (using `--add-dir` or `additionalDirectories`), produces the design, and then
     dispatches and manages sub-agents. Each agent targets a specific repository for execution.

     Generalizes the [filing-agent pattern][Giving Claude its own knowledge base]. The caller owns judgment, the agent
     owns plumbing. Centralizes the design context and scopes execution per project. Agents can also run in parallel
     when the changes are independent enough.

     Sub-agents do **not** load the target project's `CLAUDE.md` natively, and must be instructed to `Read` it
     **explicitly**. Sandbox and permission rules need to cover each target's path. Agent definitions need to exist or
     be improvised.

     Good for tasks where the design is done, and execution is plain and mechanical (file changes, config updates, role
     creation). Less useful when the execution requires judgment calls that depend on cross-project context.

  1. A coordination session (read-heavy, possibly in `plan` mode) reads all repositories, produces a concrete and
     detailed plan, and writes it somewhere persistent that all sessions can access. Per-project, independent sessions
     pick up their portion and execute. Plans are handoff artifacts.

     The plan is the shared state. It should be **concrete** (use specific file paths, propose exact diffs, contain full
     commands per each project; instructions like "update the IAM role" are not enough. The more concrete the plan, the
     less each execution session needs to re-derive and the more they stay focused on the task at hand.

     The plan also provides a natural review checkpoint between design and execution. Each execution session is fully
     scoped to its own repository, and the plan carries the design rationale alongside the actions. The downside is that
     plans can go stale if execution reveals surprises, and there is no live feedback loop. If project A's execution
     changes the plan for project B, the plan needs manual updating.

     Good for loosely-coupled tasks that benefit from a review checkpoint.<br/>
     Especially good when the user wants to review the design **before** any changes land.

     Where the plan lives can vary. It can be file at a known path (e.g. `~/.claude/plans/<task-slug>.md`), a ticket
     with per-project sections, a `deferred.md` entry with action items per repo, or a markdown document in one of the
     repositories.

- The best choice of strategy depends on how much changes are **coupled** (how much a change in repository A depends on
  the outcome of changes in repository B) and **review cadence** (does the user want to review before each changes, or
  after all of them?).

  ```text
                          Tight coupling          Loose coupling
                          ──────────────          ──────────────
  Review before each:     Plan-as-handoff         Plan-as-handoff

  Review after all:       Single session or       Separate sessions,
                          coordinator+agents      memory carries context
  ```

  An example of **tight coupling** is a Secrets Manager rotation configuration, which informs AWX's credential type,
  which informs GitLab CI variable names. Changes cascade, and each step's output is the next step's input.

  An example of **loose coupling** is creating an IAM role in an infrastructure repository, then referencing it in an
  application's CI configuration. The role ARN is the only coupling point and, once known, both projects' changes are
  independent.<br/>
  The plan-as-handoff strategy (strategy 6) seems to be the default to recommend for loosely-coupled tasks. The plan
  file provides continuity without requiring dangerous permissions or complex agent setups.

  How tightly the **planning** phase is coupled to the **execution** phase is a second axis.

  ```text
                      Planning separable     Planning entangled
                      ──────────────────     ──────────────────
  Repos loosely       Handoff via memory     Handoff via memory, but plan
  coupled:                                   needs live feedback loop

  Repos tightly       Coordinator dispatches Coordinator must stay open;
  coupled:            agents or sequences    handoff doesn't work
                      sessions
  ```

  When projects are independent **and** the planning decisions do **not** depend on execution outcomes, using memories
  for handoff works well. When they are tightly coupled **and** planning is entangled with execution (each step's output
  is the next step's input), the coordinator **must** stay open because the planning session cannot hand off what it
  has not yet decided.

- The coordinator-plus-agents pattern (strategy 5; distinct from the experimental peer-to-peer Agent Teams feature) is
  architecturally the right shape for cross-project work, but gaps prevent it from working for **reasoning-heavy**
  tasks.

  Each subagent inherits the parent's CWD, not its target project's. This means it does **not** load the target
  repository's `CLAUDE.md`, `.claude/rules/`, or `settings.json` files.<br/>
  The agent receives all instructions via its dispatch prompt, which is a fragile substitute for proper project setup.
  If the target repository's conventions change, those prompts are stale.

  The coordinator and agents pattern assumes execution to be _mechanical_, where the caller owns judgment and the agent
  owns plumbing. This works for [filing agents][Giving Claude its own knowledge base], where the content is pre-composed
  from the main session and the agent only typesets. For tasks where execution _is_ the judgment (e.g. updating a CI
  pipeline to read tokens from Secrets Manager while understanding how the rotation connects to AWX and what the
  existing code does), a mechanical agent **cannot** exercise that judgment. A reasoning-heavy session needs to do it.

  Granting agents dangerous permissions in production repositories is a matter of blast radius, not just so much one of
  safety. Multiple agents can make mistakes simultaneously, and the user cannot be present for judgment calls in each
  one.<br/>
  For a filing agent, this bet is cheap (in the worst case, a bad page can be easily reverted). For production
  infrastructure this bet can be very expensive.

- <a id="eagerness-problem"></a>
  The plan-as-handoff strategy depends on each per-repository session **faithfully** reading the shared plan, and
  confirming their own scope before acting. In practice, sessions are **eager**. They parse the plan, grab what looks
  actionable, and start exploring the code before the user has confirmed what the session should actually do.

  A per-repository session loaded auto-memory about a cross-project task, extracted a **partial** action list from the
  memory without reading the full shared plan, and began executing without asking. The memory _hinted_ at what to do
  without being authoritative, and the session treated that hint as sufficient.

  To address this:

  1. Per-repository auto-memories for a cross-project task must include a pointer to the shared plan **and** a
     **repository-scoped** list of actions.

     The plan is the source of truth and explains the reasoning behind the actions, the memory is a bookmark, and the
     list specifies **exactly** what needs to change in the specific repository (and nothing else).<br/>
     Both the pointer and the list are needed. Without the _why_, a session cannot adapt _reasonably_ when the reality
     diverges from the plan; without a **narrow** _what_, the session picks its own scope from the broader task context.

  1. A `CLAUDE.md` rule must fire when memory references an external plan. It shall force the session to read the plan
     **in full**, and to confirm its scope with the user before acting.

     This competes against the eagerness signal, which is strong. The rule needs to be mechanical (trigger-based), so
     that the model is more compelled to follow it.

  <a id="reference-checklist-for-handoff-quality"></a>

  A **reference checklist** further improves handoff quality. A cold-start session in a different repository has **no**
  context at all beyond the memory file and whatever it reads. Each per-repository memory should contain a **thorough**
  set of details, including (where applicable):

  - The repositories' URLs (not just their names).
  - Ticket IDs with full URLs.
  - Existing MRs to pattern-match against.
  - Wiki and documentation paths.
  - What is already provisioned vs what needs creating.
  - Idempotency caveats, version pins and tool-specific gotchas.
  - Credential sources (gopass paths, Secrets Manager ARNs).

  Session working on instructions with missing details have to be manually supplemented with those information.

- Cross-project task handoffs must be written to a **shared** place that (possibly) loads automatically.

  [Global memory][Giving Claude a global memory] proved optimal. The planning session's project auto-memory was very
  much not.

  The planning session naturally writes to its own project memory (`~/.claude/projects/<planning-repo>/memory/`), but
  execution sessions run in _different_ repositories and can only see their own project memory (plus global memory, if
  configured). If the handoff lives in the planning session's project memory, execution sessions cannot find it unless
  instructed to.

  A planning session ran in its own project, and wrote the task memory to that project's auto-memory. The next execution
  session (in a different repo) could not find the task's memory, and the user had to manually point to the file path
  and ask for it to be copied to global memory. A second execution session, running after the fix, found it immediately.

  Project facts normally go to auto-memory, but cross-project task facts do not belong to any single project.<br/>
  A global memory of sorts is the correct scope.

- When multiple sessions edit the same file (e.g. a shared wiki page), uncommitted changes accumulate silently.

  A planning session committed the initial wiki update. The next execution session made changes, but left them
  uncommitted (per the approval convention of the wiki). A third session found those uncommitted edits, and built on top
  of them. This worked because those sessions ran **sequentially**, and each one checked for uncommitted changes before
  editing.<br/>
  The process breaks if sessions run **concurrently** on the same file (the last writer wins), or if a session does not
  notice prior uncommitted edits.

  To mitigate this, each session should `git diff` the target before editing to see what is already changed; the
  progress log (if one is maintained in the plan) helps (e.g., "session 2 says wiki edited, not committed" tells session
  3 to _expect_ uncommitted changes).<br/>
  When using **concurrent** execution, shared file updates should be deferred to a single session or agent that runs
  after all others complete. For agent-driven concurrent execution, git worktree isolation allows each agent to work in
  its own temporary checkout, eliminating filesystem-level conflicts entirely.<br/>
  The claiming protocol (below) addresses task-level coordination, while git worktrees address file-level contention.

- The claiming protocol has a race condition window between checking for an existing claim and creating one.

  On a local filesystem, the gap between a `stat()` call and a `write()` call is sub-millisecond. Even with shell
  overhead, the practical window is under 10ms. When sessions start seconds to minutes apart (a single user following
  them, not simultaneously), the probability of two sessions claiming the same subtask in the same millisecond is
  extremely low for tasks with 10 or fewer agents.

  The consequence of a double-claim varies by subtask type:

  | Subtask            | Consequence                                             | Severity                                         |
  | ------------------ | ------------------------------------------------------- | ------------------------------------------------ |
  | Wiki edit          | Second writer overwrites first; `git diff` reveals both | Low. A review catches it.                        |
  | Ticket comment     | Duplicate comment                                       | Cosmetic. Just delete one.                       |
  | Memory update      | Last writer wins; may lose context from first writer    | Medium. Loss of information.                     |
  | Resource creation  | Could create duplicates (e.g. two MRs)                  | Medium. Requires manual cleanup.                 |
  | Destructive action | Could delete or modify twice                            | High. These actions should **not** be claimable. |

  The plan should pre-assign subtasks where duplicate work is costly (memory updates, resource creation).<br/>
  The claiming protocol is designed for subtasks where the cost of occasional duplication is **low**.

- When a session crashes mid-claim, the claim file exists with `status: in_progress` but the task will never be
  completed. After the TTL expires, the next session will pick it up. The crashed session's partial work (e.g. a
  half-written wiki edit) may be visible.

  The reclaiming session should check for partial results before starting the task from scratch.

- When a session takes longer than the TTL, another session could see the expired claim and try to reclaim it. In this
  case, two sessions will be working on the same subtask.

  The original session should renew its claim periodically, as long as it is still actively working on it.<br/>
  Should the claim be re-taken despite active work, the original session will notice it when it tries to mark the task
  `done`, as the claim file will have a different session ID.<br/>
  At that point, the session should check whether the other session completed the work, and if so, discard it's own.

- Should **all** sessions skip a subtask, each session would check claims, see nothing, but decide that "another session
  will handle it" based on a pre-assignment. This could happen when a pre-assigned session crashes without claiming.

  Critical subtasks should have a fallback note: "if repo-3's session does not claim this within 30 minutes, any session
  should."

- Stale claim files might linger from previous runs if the same dedicated directory is reused across multiple work
  sessions weeks apart (like when reusing a ticket number). In this case, old claim files may confuse new sessions.

  The planning session should clear the `claims/` directory when creating a new plan. Completed claims (`status: done`)
  are harmless as records of what was done, but `in_progress` claims older than the TTL need attention.

- The dedicated directory and the claiming protocol support the following orchestration modes equally.<br/>
  The coordination primitives (session files, claim files, read-only plan) are the same regardless of who starts the
  sessions.

  - With **manual sequencing**, the user starts the sessions one at a time. Each reads the plan and prior session's
    entries before acting. Claiming is mostly unnecessary, because the user sequences subtasks implicitly. The
    directory structure still provides visibility into what each session did.<br/>
    This is the safest mode and the one with the most evidence behind it.
  - With **user-delegated orchestration**, the user kicks off multiple sessions (potentially concurrent) and checks
    their results later. Sessions coordinate via claim files. The user reads session entries to see the aggregated
    result.<br/>
    The user dispatches but does not micromanage. The claiming protocol becomes load-bearing, because concurrent
    sessions can no longer rely on implicit sequencing to avoid duplicate work.
  - With **agent-coordinated execution**, a coordinator session dispatches sub-agents, each targeting a specific
    project. Agents write their own session entries and claim shared subtasks. The coordinator reads the directory after
    **all** agents complete, and handles any aggregation (e.g. combining wiki edits, writing a summary ticket
    comment).<br/>
    This mode is currently limited by the convention loading gap described above, where agents do **not** load their
    target repo's `CLAUDE.md` natively.

- The entire coordination protocol currently assumes a **shared local filesystem**.

  This holds for multiple terminal sessions on the **same** host, multiple Claude Code instances on the **same**
  machine, and agent teams spawned by a single coordinator (agents inherit the parent's filesystem).<br/>
  It does **not** hold for sessions running on **different** machines (CI runners, remote dev boxes), cloud-based agent
  execution (Lambda, ECS, remote containers), or cross-host collaboration (two developers running their own sessions).

  When doing remote execution, the protocol needs to address the semantics of distributed systems:

  | Local mechanism     | Remote equivalent                       |
  | ------------------- | --------------------------------------- |
  | Claim file creation | DynamoDB conditional put / Redis SETNX  |
  | TTL check           | DynamoDB TTL / Redis key expiry         |
  | Session entry file  | S3 object per session                   |
  | Directory listing   | S3 list / DynamoDB scan                 |
  | Verify-after-write  | Consistent read after conditional write |

  The remote version would gain true atomicity (conditional writes eliminate the race window entirely), but the
  complexity jump is significant.<br/>
  The local-filesystem version is sufficient for the use case used in the study (single-host, 10 or fewer agents).
  Defer the remote version until a cross-host workflow is actually needed.

- The fundamental gap this whole study tries to address is that Claude Code has **no** native concept of "task spanning
  multiple projects".<br/>
  Everything is designed around single-repository sessions. The workarounds above (additional directories, memory,
  plans, agents) each patch one aspect (context, permissions, conventions) while leaving the others broken.

  These features would close most of the remaining gap:

  - The convention loading problem (agent team members inheriting the parent's CWD instead of their target project's) is
    the single biggest obstacle to agent-coordinated execution. If an agent team member could specify
    `cwd: ~/path/to/target/repository`, `CLAUDE.md` resolution, rules, and `settings.json` would load from there
    natively.<br/>
    The coordinator would hold the cross-repo context, while each agent inherits its target project's conventions
    without needing to proxy them through the dispatch prompt. This would make the coordinator+agents strategy viable
    for reasoning-heavy tasks too, not just mechanical filing.
  - Currently, one session produces a structured handoff (plan file + memory) that another session _might_ read.<br/>
    "Available as a file" does not mean "loaded into context." A native handoff mechanism would let one session produce
    a structured artifact that the next session picks up with the plan loaded into context at session start, which would
    eliminate the gap between "the plan exists" and "the session knows about it". The user would stop needing to be the
    coordination layer between sessions, a role they currently absorb because the tooling cannot.

  Without these, the practical workaround is plan-as-handoff with memory conventions and a restraint rule. A
  coordination session produces a concrete plan, per-repo memories point to it, and each execution session reads the
  plan and confirms tier scope before acting.

## Improvements

- A **dedicated directory** per each cross-project task eliminates write contention and makes progress visible.

  Cross-project execution could rise issues like write contention (two sessions writing the same file simultaneously,
  with the last writer winning) and duplicate work (two sessions independently performing the same shared subtask,
  without knowing the other will too).<br/>
  A dedicated directory solves contention by giving each session its own file; the [claiming protocol] (below) solves
  duplicate work. Together, they form a coordination framework that works across all three orchestration modes.

  The plan file must be treated as **read-only** after the planning phase, because it is the most-read file in the
  directory,  and allowing execution sessions to edit it would reintroduce the contention the directory structure is
  meant to eliminate. If execution reveals the plan is wrong, the session notes the discrepancy in its own session file
  instead.

  ```text
  ~/.claude/plans/task-1234/
    plan.md                  # Shared plan (immutable after planning)
    claims/                  # Claim files for shared subtasks (see claiming protocol)
    session-repo-1.md        # Planning session's entry
    session-repo-2.md        # Repo 2 execution session's entry
    session-repo-3.md        # Repo 3 execution session's entry
  ```

  Each session shall create `session-<repo-or-slug>.md` when it starts, and update it as work progresses. The entry
  should be self-contained to allow a future reader to understand what this session did without reading other files.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Slug file example</summary>

  ```md
  ## Repo 2 session — 2026-06-15 12:37

  **Status**: complete
  **Session ID**: abcd0123
  **MR**: repo-2!123
  **What was done**: replication slots codified, pattern-matched against !42/!43
  **Claimed subtasks**: wiki-infrastructure, ticket-task-1234-status
  **Wiki**: Infrastructure.md edited (uncommitted)
  **Ticket**: task-1234 comment added
  **Surprises**: none — memory references were sufficient
  ```

  </details>

- Shared subtasks (wiki updates, ticket comments, memory syncs) should be **pre-assigned** in the plan, or made
  explicitly _claimable_.

  The plan should list shared subtasks separately from per-repository tasks, in two groups:

  **Pre-assigned** subtasks would be owned by a specific session, and the other sessions should skip them. Pre-assign
  works well when the planning session knows the execution order, or that a subtask must happen at a specific point
  (e.g. "final status update must be last, assign to the last session").<br/>
  Pre-assigned tasks do not need to claim files, since the assignment in the plan is authoritative.

  **Claimable** subtasks would be available first-come-first-served. Leave them claimable when the execution order is
  unpredictable, the subtask is optional, or any session could do it equally well.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example</summary>

  ```md
  ## Shared subtasks

  ### Pre-assigned

  - Wiki Infrastructure.md final update → repo-3 session (runs last, sees all changes)
  - Ticket task-1234 final status update → repo-3 session
  - Global memory status update → each session updates its own portion

  ### Claimable

  - Wiki PostgreSQL.md procedure update (if needed)
  - Clean up stale gopass entries
  ```

  </details>

- <a id="claiming-protocol"></a>
  Claimable subtasks can use a **check-claim-verify** protocol to prevent duplicate work.

  When an executing session wants to perform a claimable subtask, it shall first check the `claims/` directory for an
  existing active claim. If none exists, it shall create a claim file (`claims/<subtask-slug>.claim`) that contains its
  session ID, a timestamp, and a TTL. It shall then wait briefly (~1 second), and re-read the claim file to verify that
  its own session ID is still there; if another session overwrote it in the gap, that session won the race and this one
  shall back off.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example</summary>

  ```json
  {
    "session": "repo-1-72b40dbb",
    "claimed_at": "2026-06-15T12:35:00Z",
    "ttl_days": 3,
    "status": "in_progress"
  }
  ```

  </details>

  After completing the work, the session shall update `status` to `done`, add a `completed_at` timestamp, and write a
  brief `result` summary. It shall also record the claimed subtask in its session's entry file. A claim with
  `status: done` never expires, but shall serve as a permanent record that the work was completed.

- The [claiming protocol] shall use **TTL-based expiry** to handle sessions that crash or disconnect after claiming but
  before completing the task.

  The default TTL should be **3 days**. Sessions can run for hours (6h+ is common), and the user may step away for a
  day or more before resuming. A shorter TTL causes false expirations, where the session is still alive but its claims
  have expired, inviting duplicate work from the next session. Three days accommodates a long session, a weekend gap,
  and still expires before the task goes stale.

  | Subtask type                               | TTL     | When to override the default                                 |
  | ------------------------------------------ | ------- | ------------------------------------------------------------ |
  | Any (default)                              | 3 days  | Use this unless there is a reason not to                     |
  | Time-critical shared resource              | 1 hour  | When blocking others matters more than false expiration      |
  | Infrastructure change with rollback window | 6 hours | When the change needs verification before others build on it |

  A claim shall be expired when `now > claimed_at + ttl_days`, and `status` is still `in_progress`. An expired claim
  shall be reclaimable by any session using the normal protocol. A session doing long-running work shall renew its claim
  periodically, by updating `claimed_at` before the TTL expires.

  The TTL is meant to be a crash-recovery mechanism, not a workflow timer. Most claims should reach `done` well before
  their expiration.

- A checklist listing documentation targets to update in the plan ensures that execution sessions do not miss
  documentation updates.

  Execution sessions consistently missed documentation updates until prompted. The reference checklist covers "things to
  build" but not "things to update when done". Adding an explicit section to the shared plan closes this gap.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example</summary>

  ```md
  ## Docs to update when done

  - [ ] Wiki: Infrastructure.md — update codification status
  - [ ] task-1234 — comment + check off completed items
  - [ ] Global memory — update status (PENDING → DONE)
  ```

  </details>

  Each item shall be either pre-assigned to a specific session, or marked as claimable using the same protocol as other
  shared subtasks.

- An **append-only** progress section in the plan file gives each session both "where are we?" and "how did we get
  here?".

  When a cross-project task spans multiple sessions, each session updates the shared state, but the _progression_ is
  lost. Session 3 sees "SomeTask: DONE" without knowing _when_ it was done, _what was tried_, or _what changed_ since
  the plan was written. A progress log closes this gap by giving each session the trajectory alongside the current
  status.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example</summary>

  ```md
  ## Progress

  - 2026-06-15 11:58 — KB session: slots created, wiki committed (a1b2c3d4)
  - 2026-06-15 12:37 — repo-2 session: slots codified (!42)
  - 2026-06-15 12:55 — repo-3 session: table mapping CSVs added (!43)
  ```

  </details>

  The memory stays lean (pointer + current status) while the plan carries the full trajectory.

- For quick two-session tasks, the full task directory and claiming protocol may feel overweight. In this case, a
  **single-writer** fallback is the minimum viable convention.

  Use this fallback when the task involves two or three different projects, runs sequentially (no concurrency), and has
  few or no shared subtasks.<br/>
  Use the full protocol when sessions **may** run concurrently, when there are claimable subtasks, or when the task is
  complex enough that session-level visibility matters for debugging coordination failures.

  The planning session writes the plan file and global memory _before_ signaling that execution can begin. Each session
  writes its own session entry (even if it is just one line). Shared subtasks are all pre-assigned in the plan (no
  claiming needed).<br/>
  The handoff is "I created the memory, it is indexed, it is in the right scope, and the plan assigns every shared
  subtask to a specific session."

## Further readings

- [Claude Code]
- [Giving Claude a global memory]
- [Giving Claude its own knowledge base]

### Sources

- [Documentation / Additional directories]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Claiming protocol]: #claiming-protocol
[Reference checklist]: #reference-checklist-for-handoff-quality

<!-- Knowledge base -->
[Claude Code]: ../claude%20code.md
[Giving Claude a global memory]: global%20memory.md
[Giving Claude its own knowledge base]: own%20knowledge%20base.md

<!-- Upstream -->
[Documentation / Additional directories]: https://docs.anthropic.com/en/docs/claude-code/settings#additional-directories
