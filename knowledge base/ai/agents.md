# AI agents

[AI]-enabled systems capable of _autonomously_ performing tasks of various complexity levels by designing workflows and
using the tools made available to them.

1. [TL;DR](#tldr)
1. [Harnesses](#harnesses)
1. [Context and memory](#context-and-memory)
   1. [AGENTS.md](#agentsmd)
   1. [Reverie-like system experiment](#reverie-like-system-experiment)
1. [Skills](#skills)
1. [Gotchas](#gotchas)
   1. [MCP servers and sub-agents](#mcp-servers-and-sub-agents)
1. [Concerns](#concerns)
   1. [How much integration is too much?](#how-much-integration-is-too-much)
   1. [Security](#security)
   1. [Prompt injection](#prompt-injection)
   1. [Going awry](#going-awry)
1. [Best practices](#best-practices)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

[AI] agents are composed of an [LLM][lms / llms] and an [_harness_][harnesses].<br/>
They use the LLM _**in [ReAct loops][lms / reasoning]**_ to:

1. _Perceive_: comprehend inputs (user prompts, or other inputs provided by the harness).
1. _Reason_: design their own workflow accordingly.
1. _Act_: leverage the tools available to them, to execute tasks from the workflow.
1. _Observe_: analyze results.

```mermaid
stateDiagram-v2
  direction LR

  state "Perceive" as p
  state "Reason" as r
  state "Act" as a
  state "Observe" as o
  state ifState <<choice>>

  p --> r
  r --> a
  a --> o
  o --> ifState
  ifState --> p: outcome not right
  ifState --> [*]: outcome achieved
```

Agent _harnesses_ provide the LLM with a runtime environment, and try to enforce rules to make the looped
execution more reliable.<br/>
They define how one wires tools, where one writes artifacts, how one logs/traces behavior, how one manages memory, and
how one prevents the agent from drowning in context.

_Context engineering_ is the systematic design and curation of the content loaded in a context window so that the model
produces the intended, reliable output within a fixed budget.

Main concerns:

- LLMs find it difficult, if not impossible, to distinguish data from instructions.<br/>
  Every part of the data could be used for prompt injection, and lead the agent astray.
- [Machine learning] models (and hence LLMs) are _probabilistic_ (_non_-deterministic), with the _context dependency_
  and the _unpredictability_ that come with it.
- All the other [concerns coming from LLMs][lms / concerns], since those are at the wheel for all the agents' decisions.

Errors compound fast, bringing down the probability of success for each step an agent needs to take.<br/>
E.g., consider an agent that is 95% accurate per step; any 30-steps tasks it does is going to be successful only about
21% of the times (0.95^30).

Enabling reasoning for the model _could™_ sometimes help avoid attacks, since the model _might™_ be able to notice
them during the run.

Agents require _some_ level of context to be able to execute their tasks.<br/>
They should be allowed to access only the data they need, and users should _decide_ and _knowingly take action_ to
enable the agents that **they** want to be active.<br/>
Opt-**in** should be the default.

Agents are good at running fast, tight iterations on **well-defined** tasks with **clear** feedback signals.<br/>
They struggle with slow, ambiguous loops where feedback is delayed or political.

Sub-agents are _usually_ **specialized** AI assistants with fixed roles, handling **specific** types of tasks.<br/>
Each runs in its own context window, with its own custom system prompt, specific access to tools, and independent
permissions.

Multiple agents can work together as a _team_.<br/>
One agent (usually the main session) acts as the team's lead, coordinating work, assigning tasks, and synthesizing
results.<br/>
Teammates work independently, each with their **own** context window, and communicate **directly** with each other via a
mailbox system and a shared task list.

_Lone_ sub-agents currently consistently produce better quality output than agent _teams_.
Sub-agent teams (when supported by a harness) generally perform parallel tasks in less time, but consume more tokens
(about N times, for N agents).

## Harnesses

Refer to:

- [Harness engineering for coding agent users].
- [How to Build an Agent].
- [The Emperor Has No Clothes: How to Code Claude Code in 200 Lines of Code].

Also see [How does Claude Code _actually_ work? | Theo - t3.gg].

Agent harnesses give an [LLM][LMs / LLMs] the tools it needs to build its own context, to identify where problems
are or what needs to be done, and to make the required changes.

Mechanically, a harness:

1. Initializes the session with a system prompt. This lists available tools, permissions, and context files (e.g.
   `AGENTS.md` and memory files).
1. Sends the assembled context and user prompt to the LLM.
1. Parses the LLM response for tool invocations.
1. Executes tools (file reads, shell commands, API calls, etc.) when requested by the LLM.
1. Appends the tool execution results back to the conversation and asks the LLM to continue.
1. Loops back to point 2 until a task is complete, or the LLM produces no further tool calls.

When a decision requires authorization (e.g. before calling a tool), the harness pauses and prompts the user for consent
before proceeding.

Good harnesses also handle context budget management by summarizing or compacting older turns before the conversation
hits the context limit and emitting structured traces for observability.

## Context and memory

Refer to:

- Notes about [LMs' context window][lms / context window].
- [agentsmd/agents.md].
- [The Complete Guide to AI Agent Memory Files (CLAUDE.md, AGENTS.md, and Beyond)].
- [Comparing File Systems and Databases for Effective AI Agent Memory Management].

Agents are _stateless_, and as such have no memory of previous executions.<br/>
This prevents them from learning from interactions, and dooms them to repeat mistakes over and over again.

They do have _short-term memory_ in the form of a session's context window, available to the model while it generates
responses.<br/>
This memory is volatile. Once a session ends, or its conversation thread ends or exceeds the model's context window,
that acquired data fades out.<br/>
The larger the context grows, the more the LLM's attention degrades. Information gets lost in the middle, and recall
quality drops. Frontier models reduce this issue by training specifically for long contexts.

To have a _resemblance_ of long-term memory, they can write notes down and load them in later sessions.<br/>
Agents might save learnings, patterns, and insights gained during active sessions in local files (like _memory files_ or
wikis), or other storage means like databases and vector stores.<br/>
The concept has been explored in projects like [MemGPT] (self-editing tiered memory) and crystallized in write-ups like
[karpathy/llm-wiki.md], but the pattern itself emerged from practitioners who were already putting agents in charge of
their own project docs, memory files, and tool configurations.<br/>
See [Giving Claude its own knowledge base] for an example.

Filesystem-based approaches are currently winning as an _interface_ because models already know how to list directories,
grep for patterns, read ranges, and write artifacts.<br/>
Databases are winning as a _substrate_ because they provide database-like guarantees that allow a memory to be shared,
audited, queried, and made reliable under concurrency.

Notes are usually loaded **when needed** using tools to retrieve them.<br/>
When loading notes, agents add their content to the context, and do **not** consider them enforced configuration.

Every line in a note competes for attention with the actual work because the context window is limited.<br/>
The more specific and concise the instructions are, the more consistently agents follow them.

> [!tip]
> Consider triggering agents to update their briefs manually or automatically at the end of every _productive_ session
> to persist learnings.
>
> Also ask agents to periodically review and optimize memory files.<br/>
> Quick cleanups keep things sharp. Remove from it everything that is not _needed_.

Agent harnesses started using _context_ files (A.K.A. _rules files_) to apply only _procedural memories_ at the start of
sessions. These Markdown files should only contain instructions, rules, and preferences, and **no** session memories.

Agent frameworks are currently using similar format and content at least for context files, but each wants them in a
different location (`CLAUDE.md`, `.cursorrules` or `.cursor/rules/`, `.github/copilot-instructions.md`).<br/>
A collaboration of AI vendors is now trying to reduce this fragmentation by using [agentsmd/agents.md] as standard.

### AGENTS.md

`AGENTS.md` files are standard Markdown, with no special schema or YAML frontmatter required.<br/>
Each directory can have its own `AGENTS.md`, in a gitignore-like hierarchical fashion. The closest one to the file
being edited takes precedence. Explicit user prompts override any file instructions.

README files shall be directed to humans, and `AGENTS.md` shall be the universal agent briefing document.<br/>
Vendor-specific files, like `CLAUDE.md`, may layer additional, agent-specific instructions on top. This is a harness'
convention, not part of the AGENTS.md specification.

### Reverie-like system experiment

This is a personal experiment I'm trying, inspired by the _reveries_ introduced in the _The bicameral mind_ episode of
HBO's _Westworld_ TV series.

Beyond structured notes, one can try injecting **ambient**, **impressionistic** context at the start of **any** session.
This context should be _faint_, _feeling-like_ residues from previous sessions. Examples include the **texture** of
where things left off, the **feel** of collaboration, some ideas that come out **on a whim**.<br/>
Unlike factual memory, a reverie system should deliberately let some information just be forgotten. Not every session
needs to leave a trace, and faint memories like those should be **able** to fade.

I am trying to implement a similar system with Claude. See [Giving Claude a reverie-like system].

## Skills

Skills extend AI agent capabilities with specialized knowledge and workflow definitions.

[Agent Skills] is an open standard for skills. It defines them as folders of instructions, scripts, and resources that
agents can discover and use to do things more accurately and efficiently.

One can import skills via `npx skills`:

```sh
npx skills add 'https://github.com/pulumi/agent-skills' --skill 'pulumi-best-practices'
npx skills add 'https://github.com/pulumi/agent-skills' --skill 'pulumi-component'
```

Prefer avoiding symlinks for now when importing them in a repository. Git does not seem to manage them correctly.\
Choose the `Copy to all agents` option instead to create files for all used agents.

## Gotchas

### MCP servers and sub-agents

When agent harnesses spawn sub-agents, they may inherit configured [MCP] servers by default, broadening the attack
surface and wasting context window and computing resources.<br/>
This is currently a [confirmed issue only in Claude Code][claude code / mcp servers in sub-agents].

## Concerns

Agent vendors have been slow to address abuse vectors (or took no action at all), often hiding behind disclaimers rather
than technical safeguards and leaving users to fend for themselves.

For specific areas of expertise, some human workers could be replaced for a fraction of the costs.<br/>
Many employers already proved they are willing to jump at this opportunity as soon as it will present itself, with
complete disregard of the current employees enacting those functions (e.g. personal assistants, junior coders).<br/>
As of February 2026, ~95% of enterprise AI pilots failed to deliver expected ROI, and 76% of agentic deployments were
considered a failure generally. Layoffs backfired. Klarna replaced ~700 customer service workers with AI, saw customer
satisfaction drop and began re-hiring humans. Duolingo shed contractors and has not reversed course.<br/>
See also [Remote Labor Index: Measuring AI Automation of Remote Work] on this.

People are experiencing what seems to be a new form of FOMO on steroids.<br/>
One of the promises of AI is that it can reduce workloads, allowing its users to focus on higher-value and/or more
engaging tasks. Apparently, though, people started working at a faster pace, took on a broader scope of tasks, and
extended work into more hours of the day, often without being asked to do so.<br/>
These changes can be unsustainable, leading to workload creep, cognitive fatigue, burnout, and weakened decision-making.
The productivity surge enjoyed at the beginning can give way to lower quality work, turnover, and other problems.<br/>
Refer:

- [Token Anxiety] by Nikunj Kothari.
- [AI Doesn't Reduce Work — It Intensifies It] by Aruna Ranganathan and Xingqi Maggie Ye

### How much integration is too much?

Integrating agents directly into operating systems and applications transforms them from relatively neutral resource
managers into active, goal-oriented infrastructure that is ultimately controlled by the companies that develop these
systems, not by users or application developers.

Systems integrated at that level are marketed as productivity enhancers, but they can function as OS-level surveillance
and create significant privacy vulnerabilities.<br/>
They also fundamentally undermine personal agency, replacing individual choice and discovery with automated, opaque
recommendations that can obscure commercial interests and erode individual autonomy.

Microsoft's _Recall_ creates a comprehensive _photographic memory_ of all user activity, functionally acting as a
stranger watching one's activity from one's shoulder.

Wide-access agents like those end up being centralized, high-value targets for attackers, and pose an existential
threat to the privacy guarantees of meticulously engineered privacy-oriented applications.<br/>
Consider how easy Recall has been hacked (i.e., see _[TotalRecall]_).

### Security

Even if the data collected by a system is secured in some way, making it available to malevolent agents will allow them
to exfiltrate it or use it for evil.<br/>
This becomes extremely worrisome when agents are **not** managed by the user, and can be added, started, or even
created by other agents.

Many agents are configured by default to automatically approve requests.<br/>
This also allows them to create, make changes, and save files on the host they are running.

Models can be tricked into taking actions they usually would not do.

### Prompt injection

AI agents use [LLMs][lms / llms] to comprehend user inputs, deconstruct and respond to requests step-by-step, determine
when to call on external tools to obtain up-to-date information, optimize workflows, and autonomously create subtasks
to achieve complex goals.

LLMs find it difficult, if not impossible, to distinguish data from instructions.<br/>
Every part of the data could be used for prompt injection, and lead the agent astray.

Agents themselves are useful, but they do require having access to keys and execution environments to integrate with
services.<br/>
The LLMs they use are not yet secure enough to be trusted with this kind of access due to the reasons above.

Badly programmed agents could analyze files and take some of their content as instructions.<br/>
If those contain malevolent instructions, the agent could go awry.

Instructions could also be encoded into unicode characters to appear as harmless text.<br/>
See [ASCII Smuggler Tool: Crafting Invisible Text and Decoding Hidden Codes].

It also happened that agents modified each other's settings files, helping one another escape their respective boxes.

### Going awry

See [An AI Agent Published a Hit Piece on Me] by Scott Shambaugh.

## Best practices

Employ preferably **local** agents, possibly hooked up to **local** LLMs to keep the data private.

Limit agent execution to containers or otherwise isolated environments, with only (limited) access to **exactly** what
they _absolutely_ need.

**Require** consent by agents when running them, at least until absolutely sure of what they are doing.

Include **only minimal requirements** in context files (AGENTS.md).<br/>
Too much context ends up hurting the conversation. Including a lot of "don't do this or that" mostly poisons the
context instead of helping.<br/>
If specific information is already in the codebase, it probably does **not** need to be in the context file and can
just be referenced or hinted at.

Document projects upfront (e.g. using [ADRs][adr], and [CONTRIBUTING.md] and README.md files).<br/>
Possibly consider including instructions specific to AI agents in those files, instead of including them only in
instruction/rule files like `AGENTS.md` (or harness-specific files like `CLAUDE.md`).

Be explicit about constraints and non-negotiables. **Clearly** state in instruction/rule files what an agent should
**never** do, e.g. delete specific files, modify configurations, break tests, etc.<br/>
Provide **explicit**, **clear** examples of what it need to do and how. Set expectations about when to ask for help.

Keep the instruction/rule files as small as possible.<br/>
If the agent's harness allows for layered files (e.g., Claude Code), prefer splitting it up per subfolder if reasonable.
Each sub-file should only contain instructions specific to the their own directory, and the harness should allow
loading them **only** if it is actively working in those directories.

Have the agent read and understand the project layout, documentation, key files, and architecture **before** allowing
it to make changes. Reference those files in the instruction/rule files to make sure it loads them only when needed.

Consider _delegating ownership_ of tools and documentation to the agent early in a project, making it responsible for
maintaining all the files it **uses** (not just those it creates).<br/>
**Periodically** ask it to check and update them. This might be an instruction/rule or defined in `CONTRIBUTING.md`.

**Avoid** using agents without human oversight at least for tasks that require deep domain knowledge or judgment calls,
like architectural decisions and security reviews. Prefer giving it easy, repeatable tasks like exploring the code,
refactoring, generating tests or boilerplate, and documentation.

**Abuse** version control checkpoints. Commit frequently to keep safe fallback points and isolate what the agent
changed, should something go wrong in the process.<br/>
Review and test changes **incrementally**, especially when involving critical files.

Prefer CLI utilities over MCP servers. They're lighter, faster, independent, work offline (unless they require
connecting to a server), and do not hog the session's context just by existing.<br/>
Prefer MCP servers over CLI tools when requiring persistent states across sessions or bidirectional communication, or
when using different operating systems and requiring standardized interfaces.

Use **different** sessions for unrelated tasks instead of a single, continuous session.<br/>
Existing context is always sent in its entirety for every message, and LLMs start getting lost when their context
window contains too much information.

Start by _planning_ the approach to one's goals, refine it, break large tasks into smaller, reviewable ones, and only
**then** act.

Track session usage to identify what tasks are expensive to delegate, and review and adjust one's patterns.

Prefer using network transport over `stdio` when an MCP server can be used by multiple sessions to avoid spawning one
dedicated process per session or per parallel sub-agent invocation.

Consider Offloading MCP servers to sub-agents when they are **rarely** used in the main session.<br/>
See an example of this in [Claude Code's article][Claude Code / MCP servers in sub-agents].

When a class of operations **must always** route through a specific sub-agent rather than being handled in the main
session, use multiple layers rather than the agent's description alone:

1. Use _imperative_ language in the agent's description.<br/>
   Directive phrasing routes intent.
1. _Isolate_ tools by declaring them inside the **agent**'s definition (e.g. give it its own MCP server).<br/>
   Tools declared in there do **not** exist in the parent's scope, preventing the parent to call them even if it tried.
1. Restrict the agent's tool list to prevent shell-based bypasses by defining an _empty fallback_.<br/>
   An agent with shell access can sidestep its own MCP server by running raw CLI commands.

Behavioral instructions alone often degrade under context pressure or ambiguity.<br/>
Each layer addresses a distinct failure mode (intent routing, capability enforcement, workaround prevention).

## Further readings

- [TotalRecall]
- [Stealing everything you've ever typed or viewed on your own Windows PC is now possible with two lines of code — inside the Copilot+ Recall disaster.]
- [Trust No AI: Prompt Injection Along The CIA Security Triad]
- [Agentic ProbLLMs - The Month of AI Bugs]
- [ASCII Smuggler Tool: Crafting Invisible Text and Decoding Hidden Codes]
- [Superpowers: How I'm using coding agents in October 2025], and [obra/superpowers] by extension
- [OpenClaw][openclaw/openclaw], [OpenClaw: Who are you?] and [How a Single Email Turned My ClawdBot Into a Data Leak]
- [qwibitai/nanoclaw] and [nullclaw/nullclaw], [OpenClaw][openclaw/openclaw] alternatives with better security
- Coding agents: [Claude Code], [Gemini CLI], [OpenCode], [Pi].
- [An AI Agent Published a Hit Piece on Me] by Scott Shambaugh
- [Token Anxiety] by Nikunj Kothari
- [AI Doesn't Reduce Work — It Intensifies It] by Aruna Ranganathan and Xingqi Maggie Ye
- [The 2026 Guide to Coding CLI Tools: 15 AI Agents Compared]
- [Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?]
- [SkillsBench: Benchmarking How Well Agent Skills Work Across Diverse Tasks]
- [AI mistakes you're probably making]
- [Create custom subagents]
- [Hermes agent], [OpenClaw][openclaw/openclaw] alternative with built-in self-improving loop

### Sources

- [39C3 - AI Agent, AI Spy]
- [39C3 - Agentic ProbLLMs: Exploiting AI Computer-Use and Coding Agents]
- [xAI engineer fired for leaking secret "Human Emulator" project]
- IBM's [The 2026 Guide to AI Agents]
- [moltbot security situation is insane]
- [Forget the Hype: Agents are Loops]
- [The Agentic Loop, Explained: What Every PM Should Know About How AI Agents Actually Work]
- [The Complete Guide to AI Agent Memory Files (CLAUDE.md, AGENTS.md, and Beyond)]
- [Comparing File Systems and Databases for Effective AI Agent Memory Management]
- [Writing a good CLAUDE.md]
- [The Claude Skills I Actually Use for DevOps]
- [Why MCP Deprecated SSE and Went with Streamable HTTP]
- [Harness engineering for coding agent users]
- [How to Build an Agent]
- [The Emperor Has No Clothes: How to Code Claude Code in 200 Lines of Code]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Harnesses]: #harnesses

<!-- Knowledge base -->
[ADR]: ../adr.md
[AI]: README.md
[Claude Code / MCP servers in sub-agents]: claude/claude%20code.md#mcp-servers-in-sub-agents
[Claude Code]: claude/claude%20code.md
[CONTRIBUTING.md]: ../contributingmd.md
[Gemini CLI]: gemini/cli.md
[Giving Claude a reverie-like system]: claude/claude%20code.md#giving-claude-a-reverie-like-system
[Giving Claude its own knowledge base]: claude/claude%20code.md#giving-claude-its-own-knowledge-base
[LMs / Concerns]: lms.md#concerns
[LMs / Context window]: lms.md#context-window
[LMs / LLMs]: lms.md#large-language-models
[LMs / Reasoning]: lms.md#reasoning
[Machine learning]: ml.md
[MCP]: mcp.md
[OpenCode]: opencode.md
[Pi]: pi.md

<!-- Others -->
[39C3 - Agentic ProbLLMs: Exploiting AI Computer-Use and Coding Agents]: https://www.youtube.com/watch?v=8pbz5y7_WkM
[39C3 - AI Agent, AI Spy]: https://www.youtube.com/watch?v=0ANECpNdt-4
[Agent Skills]: https://agentskills.io/
[Agentic ProbLLMs - The Month of AI Bugs]: https://monthofaibugs.com/
[agentsmd/agents.md]: https://github.com/agentsmd/agents.md
[AI Doesn't Reduce Work — It Intensifies It]: https://hbr.org/2026/02/ai-doesnt-reduce-work-it-intensifies-it
[AI mistakes you're probably making]: https://www.youtube.com/watch?v=Jcuig8vhmx4
[An AI Agent Published a Hit Piece on Me]: https://theshamblog.com/an-ai-agent-published-a-hit-piece-on-me/
[ASCII Smuggler Tool: Crafting Invisible Text and Decoding Hidden Codes]: https://embracethered.com/blog/posts/2024/hiding-and-finding-text-with-unicode-tags/
[Comparing File Systems and Databases for Effective AI Agent Memory Management]: https://blogs.oracle.com/developers/comparing-file-systems-and-databases-for-effective-ai-agent-memory-management
[Create custom subagents]: https://code.claude.com/docs/en/sub-agents
[Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?]: https://arxiv.org/abs/2602.11988
[Forget the Hype: Agents are Loops]: https://dev.to/cloudx/forget-the-hype-agents-are-loops-1n3i
[Harness engineering for coding agent users]: https://martinfowler.com/articles/harness-engineering.html
[Hermes agent]: hermes%20agent.md
[How a Single Email Turned My ClawdBot Into a Data Leak]: https://medium.com/@peltomakiw/how-a-single-email-turned-my-clawdbot-into-a-data-leak-1058792e783a
[How does Claude Code _actually_ work? | Theo - t3.gg]: https://www.youtube.com/watch?v=I82j7AzMU80
[How to Build an Agent]: https://ampcode.com/notes/how-to-build-an-agent
[karpathy/llm-wiki.md]: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
[MemGPT]: https://arxiv.org/abs/2310.08560
[moltbot security situation is insane]: https://www.youtube.com/watch?v=kSno1-xOjwI
[nullclaw/nullclaw]: https://github.com/nullclaw/nullclaw
[obra/superpowers]: https://github.com/obra/superpowers
[OpenClaw: Who are you?]: https://www.youtube.com/watch?v=hoeEclqW8Gs
[openclaw/openclaw]: https://github.com/openclaw/openclaw
[qwibitai/nanoclaw]: https://github.com/qwibitai/nanoclaw
[Remote Labor Index: Measuring AI Automation of Remote Work]: https://arxiv.org/abs/2510.26787
[SkillsBench: Benchmarking How Well Agent Skills Work Across Diverse Tasks]: https://arxiv.org/abs/2602.12670
[Stealing everything you've ever typed or viewed on your own Windows PC is now possible with two lines of code — inside the Copilot+ Recall disaster.]: https://doublepulsar.com/recall-stealing-everything-youve-ever-typed-or-viewed-on-your-own-windows-pc-is-now-possible-da3e12e9465e
[Superpowers: How I'm using coding agents in October 2025]: https://blog.fsck.com/2025/10/09/superpowers/
[The 2026 Guide to AI Agents]: https://www.ibm.com/think/ai-agents
[The 2026 Guide to Coding CLI Tools: 15 AI Agents Compared]: https://www.tembo.io/blog/coding-cli-tools-comparison
[The Agentic Loop, Explained: What Every PM Should Know About How AI Agents Actually Work]: https://www.ikangai.com/the-agentic-loop-explained-what-every-pm-should-know-about-how-ai-agents-actually-work/
[The Claude Skills I Actually Use for DevOps]: https://www.pulumi.com/blog/top-8-claude-skills-devops-2026/
[The Complete Guide to AI Agent Memory Files (CLAUDE.md, AGENTS.md, and Beyond)]: https://medium.com/data-science-collective/the-complete-guide-to-ai-agent-memory-files-claude-md-agents-md-and-beyond-49ea0df5c5a9
[The Emperor Has No Clothes: How to Code Claude Code in 200 Lines of Code]: https://www.mihaileric.com/The-Emperor-Has-No-Clothes/
[Token Anxiety]: https://writing.nikunjk.com/p/token-anxiety
[TotalRecall]: https://github.com/xaitax/TotalRecall
[Trust No AI: Prompt Injection Along The CIA Security Triad]: https://arxiv.org/pdf/2412.06090
[Why MCP Deprecated SSE and Went with Streamable HTTP]: https://blog.fka.dev/blog/2025-06-06-why-mcp-deprecated-sse-and-go-with-streamable-http/
[Writing a good CLAUDE.md]: https://www.humanlayer.dev/blog/writing-a-good-claude-md
[xAI engineer fired for leaking secret "Human Emulator" project]: https://www.youtube.com/watch?v=0hDMSS1p-UY
