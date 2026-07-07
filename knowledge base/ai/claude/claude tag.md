# Claude @tag

Anthropic's persistent AI team member for Slack. Different surface from [Claude Code], Claude Desktop, and the
[claude.ai][website] web app.

1. [TL;DR](#tldr)
1. [Security](#security)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Claude @tag lets teams tag `@Claude` in Slack channels to delegate tasks.<br/>
It connects to _public_ external tools (like GitLab, GitHub, and others), acts on codebases and workflows, and operates
asynchronously and autonomously.

It is designed for **team-based** workflows, and replaces the previous _Claude in Slack_ app.

Currently in **beta**, only runs on **Opus 4.8**, and available to **Enterprise** and **Team** plan customers only.
Slack-exclusive at launch, with stated plans to expand to other platforms.<br/>

It can:

- Break down tasks, and execute them in multiple stages.
- Retain channel context and build memory over time.
- Handle tasks asynchronously by scheduling work across hours or days.
- Proactively post updates via an _ambient behavior_ mode.
- Receive direct messages privately.<br/>
  When doing so, it is equipped with its own separate access to tools.

Each Slack channel gets a separate Claude _identity_ with isolated memories and permissions. A channel's Claude instance
does **not** share context with another channel's Claude. Private channels stay confidential.

Administrators control which tools and data Claude can access per channel. They can set token spending limits at both
the organization and channel level. Audit logging is available.

When connected to a code hosting platform (e.g. GitLab), Claude @tag can clone repositories, read and search projects,
comment on issues and merge requests, and check pipeline status.<br/>
The connection uses a service account with a personal access token, proxied through Anthropic's Agent Proxy so the model
and the sandbox never see the raw token.

Decide the tool to use depending on the kind of work:

| Action                                     | Best surface      |
| ------------------------------------------ | ----------------- |
| Team-wide task delegation from Slack       | Claude @tag       |
| Individual terminal or IDE coding sessions | [Claude Code]     |
| Interacting with web pages in a browser    | Claude for Chrome |
| Programmatic API integrations              | Claude API        |

## Security

Repository source code is cloned to Anthropic's [gVisor sandbox infrastructure][containment architecture] for code
execution. The Claude Code CI/CD integration runs on the platform's own runners instead.

The code hosting instance (e.g. GitLab, GitHub) **must** be reachable from Anthropic's servers through the public
internet.

Be mindful of data sensitivity when connecting repositories. Code and context from connected projects are sent to
Anthropic's infrastructure, even if transiently.

## Further readings

- [Claude Code]
- [Claude for Chrome]
- [Claude]

### Sources

- [Introducing Claude @tag]
- [Containment architecture]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[Claude Code]: claude%20code.md
[Claude for Chrome]: claude%20for%20chrome.md
[Claude]: README.md

<!-- Upstream -->
[Containment architecture]: https://www.anthropic.com/engineering/how-we-contain-claude
[Introducing Claude @tag]: https://www.anthropic.com/news/introducing-claude-tag
[Website]: https://claude.com/product/overview
