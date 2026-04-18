# Claude for Chrome

Chrome browser-specific extension that runs [Claude] in a side panel and lets it interact with the current page.<br/>
Different surface from [Claude Code], Claude Desktop, and the claude.ai web app.

1. [TL;DR](#tldr)
1. [Security](#security)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

The Anthropic ecosystem offers two distinct Google Docs integrations:

| Surface           | Capability                                            | How it works                  |
| ----------------- | ----------------------------------------------------- | ----------------------------- |
| claude.ai web     | **Read** documents' text and add it to a conversation | Text extraction via Drive API |
| Claude for Chrome | **Interact** with open documents                      | Browser UI automation         |

Prefer the Chrome extension for _editing_.<br/>
Prefer the Drive integration when _just reading_.

The extension allows Claude to:

- Operate across **all open tabs in a designated tab group**.
- Keep working when one switches tabs.<br/>
  Chrome must stay open, and notifications fire on required permissions and on completion.
- Record one doing a task, to then learn to repeat it.
- Execute recurring, browser-based scheduled tasks.

Claude for Chrome, [Claude Code], and Claude Desktop use **separate** Claude instances, each with its **own** toolset
and conversation context.<br/>
Enabling Claude for Chrome does **not** give Claude Code the ability to act in the browser. Bridge them manually by
pasting output, share documents, etc. between the two.

Decide the tool to use depending on whether the action is UI-shaped or API-shaped:

| Action                                                      | Best surface                                       |
| ----------------------------------------------------------- | -------------------------------------------------- |
| Edit a Google Doc (ad-hoc)                                  | Claude for Chrome                                  |
| Edit a Google Doc as part of a **programmatic** workflow    | MCP server (Google Docs API)                       |
| Add the contents of a Google Doc to a conversation context  | claude.ai Drive integration                        |
| Run code, edit local files, drive a terminal session        | [Claude Code]                                      |
| Operate against an authenticated web app with no public API | Claude for Chrome                                  |
| Operate against a service with a stable, supported API      | MCP server (more deterministic than UI automation) |

UI automation is inherently **less** deterministic than API calls.<br/>
Choose Chrome when an API isn't available or isn't worth integrating; choose MCPs when you want repeatability.

## Security

Anthropic blocked Claude for Chrome from using websites from certain high-risk categories such as financial services,
adult content, and pirated content.<br/>
For Teams/Enterprise plans, admins can set site allowlists and blocklists.

## Further readings

- [Claude Code]
- [Claude for Chrome product page]

### Sources

- [Piloting Claude in Chrome]
- [Get started with Claude in Chrome]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[claude]: ../README.md
[claude code]: claude%20code.md

<!-- Upstream -->
[claude for chrome product page]: https://claude.com/claude-for-chrome
[get started with claude in chrome]: https://support.anthropic.com/en/articles/12012173-getting-started-with-claude-for-chrome
[piloting claude in chrome]: https://claude.com/blog/claude-for-chrome
