---
name: gitlab-wiki
description: >-
  Fetch and read wiki pages from a GitLab instance via MCP or the gitlab CLI. This skill provides
  the only way to access GitLab wiki content — without it, you cannot read ADRs, runbooks,
  team standards, or any wiki-hosted documentation. You MUST use this skill whenever the user asks
  about wiki pages, ADRs, runbooks, internal docs, knowledge base articles, design decisions,
  team standards, conventions, or internal best practices stored in GitLab. Trigger on questions
  like "what's our standard for X", "is there a runbook for Y", "check the docs on Z", "what
  does the ADR say about...", "look up the wiki page for...", or any request to find, browse, or
  read existing team knowledge hosted in a GitLab group or project wiki. If the user mentions a
  wiki page by name or asks to list available documentation, use this skill — do not try to answer
  from memory, because the content lives in GitLab and you do not have it.
argument-hint: [what to read, e.g. "ADR 0002 from devops group wiki"]
---

# GitLab Wiki Reader

Read-only skill. Do not create, edit, or delete wiki pages.

**Request:** $ARGUMENTS

<!-- Customize: replace <YOUR_DEFAULT_GROUP> with your team's default wiki group path -->

## Step 1: Identify the target

From the request, determine:

- **Scope**: group or project? Default to `<YOUR_DEFAULT_GROUP>` when unspecified.
- **Page**: slug, title fragment, or topic (e.g. "ADR 01", "ECS service", "Mimir sizing")

If the group/project was already resolved earlier in this conversation, reuse it.

## Step 2: Find the page

Use the **first method that applies**:

**A) Slug already known** — go straight to Step 3.

**B) MCP search** (preferred — faster, searches titles and content server-side):

The tool name depends on how the GitLab MCP server is configured. Look for a tool matching
`mcp__*gitlab*__search` in the available tools. Common names:

- GitLab plugin: `mcp__plugin_gitlab_gitlab__search`
- Standalone server named `gitlab`: `mcp__gitlab__search`

Call whichever is available:

```plaintext
mcp__<server>__search(scope="wiki_blobs", search="<query>", group_id="<group-path>")
```

`group_id` takes the group **path** string (e.g. `"devops"`), not a numeric ID.
Multiple matches? Present the top results with their slugs and ask the user to pick.

If no GitLab MCP search tool is available, skip to method C.

**C) CLI fallback** (when no MCP search tool exists or search returns nothing):

Resolve the numeric group/project ID if you don't already have it:

```bash
gitlab -o 'json' group list --search "<name>"
# or: gitlab -o 'json' project list --search "<name>"
```

Then list pages:

```bash
# Group wiki (use --per-page 100; default of 20 truncates)
gitlab -o 'json' group-wiki list --group-id '<id>' --per-page '100'

# Project wiki
gitlab -o 'json' project-wiki list --project-id '<id>' --per-page '100'
```

Match loosely — "ADR 02" matches any slug or title containing "02".
Add `--get-all` if the wiki has more than 100 pages (can be slow).
Ask the user to disambiguate if multiple results match.

## Step 3: Fetch and present

```bash
gitlab -o 'json' group-wiki get --group-id '<id>' --slug '<slug>'
# For project wikis:
gitlab -o 'json' project-wiki get --project-id '<id>' --slug '<slug>'
```

Pass slugs as-is (e.g. `ADRs/02-ECS-and-load-balancers`) — python-gitlab handles URL encoding.
Extract the `content` field for the Markdown body.

If the user asked a specific question, summarize and quote the relevant sections rather than
dumping the full page. Mention any linked wiki pages (`[[Page Name]]` or relative links) so the
user can ask for follow-ups.

## Error handling

| Error                                        | Cause                          | Fix                                 |
| -------------------------------------------- | ------------------------------ | ----------------------------------- |
| `permission denied` / `No config file found` | Sandbox blocking config read   | See `setup.md` in this directory    |
| 404                                          | Wrong slug                     | List pages to find the correct slug |
| 403                                          | Insufficient PAT scope         | Needs `read_api` scope              |
| `gitlab: command not found`                  | Not installed                  | `pipx install 'python-gitlab'`      |

## Setup (first run only)

See `setup.md` in this skill's directory for configuration options (config file, sandbox
allowlist, env vars).

<!-- Install: copy this directory to $HOME/.claude/skills/gitlab-wiki/ -->
