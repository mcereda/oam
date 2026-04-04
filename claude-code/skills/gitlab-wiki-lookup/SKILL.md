---
name: gitlab-wiki-lookup
description: >-
  Search GitLab wikis, runbooks, and ADRs for organizational knowledge. Invoke
  this skill in two situations: (1) when the user asks questions that likely
  have a company-specific answer — deployment processes, architecture decisions,
  service ownership, team conventions, environment setup, secrets management,
  database migration procedures, coding standards, release processes, onboarding
  steps, incident response; and (2) before the user takes action that could have
  company conventions — creating new services or projects, modifying shared
  configurations, changing database schemas, setting up environments, adding
  integrations, or provisioning cloud resources. The wiki often has naming
  conventions, required steps, approval processes, or guardrails not found in
  code. Also trigger for "why" questions about design choices, "how do I/we"
  questions about internal processes, and phrases like "in our setup", "what
  should I know before", or "anything I need to mind". Even when code is present
  in the repo, company-wide conventions often live in the wiki, not in the
  codebase. If the user explicitly mentions wikis, runbooks, or ADRs, always
  invoke.
argument-hint: 'what to look up, e.g. "search for deploy guide in project wiki"'
---

# GitLab Wiki Lookup

Read wiki pages from a GitLab instance using whichever tools are available.

**Request:** $ARGUMENTS

## Step 0: Check tool availability

Before doing anything, verify that at least one wiki-access method exists in
this session. Check in order:

1. **GitLab MCP tools** — look for any tool prefixed with `mcp__` that relates
   to GitLab and supports a `search` operation with `scope: "wiki_blobs"`.
2. **`gitlab` CLI** — run `which gitlab` to check if python-gitlab is installed.
3. **Local wiki checkout** — check if the current directory (or a sibling) is a
   `.wiki.git` clone, or use Glob to look for wiki-style `.md` files.

If **none** of these are available and nothing in the environment points to
GitLab (no GitLab remote in `git remote -v`, no MCP tools), stop early and tell
the user:

> "I don't have a way to access GitLab wikis in this session. If your team uses
> GitLab wikis, you can set up access by adding the GitLab MCP server,
> installing the `gitlab` CLI, or cloning the wiki repo locally."

Then read and share the relevant parts of `setup.md` from this skill's
directory.

## Detecting the current context

When the user does not specify a group or project, infer it from the current git
repository. Run:

```bash
git remote -v
```

Parse the first GitLab remote URL. Common formats:

| Format        | Example                                               | Extract project path                     |
| ------------- | ----------------------------------------------------- | ---------------------------------------- |
| SSH           | `git@gitlab.example.com:group/project.git`            | strip before `:`, strip `.git`           |
| HTTPS         | `https://gitlab.example.com/group/project.git`        | strip scheme + host, strip `.git`        |
| SSH with port | `ssh://git@gitlab.example.com:2222/group/project.git` | strip scheme + host + port, strip `.git` |

From the project path, derive:

- **Group path**: drop the last segment (e.g. `group/subgroup/project` ->
  `group/subgroup`)
- **GitLab host**: extract from the URL (useful for CLI config context)

**Edge cases:**

- **No git repo** (no `.git` directory): ask the user which group or project to
  search.
- **No GitLab remote** (e.g. GitHub only): inform the user and ask for a GitLab
  target.
- **Multiple remotes**: prefer `origin`. If `origin` is not GitLab, check
  others. If multiple GitLab remotes exist, list them and ask the user to pick.
- **Wiki repo** (URL ends with `.wiki.git`): strip `.wiki` — you are inside a
  wiki checkout. Use the parent project path.

Once you have the project path:

- **MCP tools** accept path strings directly as `group_id` or `project_id` — no
  numeric lookup needed.
- **CLI commands** need numeric IDs — see "Looking up group or project IDs"
  below.

If auto-detection fails or the user specifies a different target, use their
explicit scope.

## Choosing your tools

Check what is available in this session and prefer MCP when it exists — it is
faster, avoids sandbox configuration, and can search content server-side.

### GitLab MCP tools (preferred)

Find the GitLab MCP `search` tool (prefix varies: `mcp__plugin_gitlab_gitlab__`,
`mcp__gitlab__`, etc.) and call it with:

- `scope`: `"wiki_blobs"`
- `search`: the query string
- `group_id`: the group **path** (e.g. `"my-team"` or `"my-org/my-team"`)
- or `project_id`: the project **path** (e.g. `"my-org/my-project"`)

Results include content snippets alongside page paths. For straightforward
questions, the snippets alone may contain the answer — check before doing a full
page fetch.

### `gitlab` CLI (second choice)

The `gitlab` CLI (python-gitlab) works everywhere but requires a configuration
file with connection details and a personal access token. If you encounter
`No config file found` or `permission denied`, read `setup.md` in this skill's
directory for setup instructions and walk the user through it.

### Local checkout (last resort, but fast)

GitLab wikis are git repositories. If the wiki is cloned locally (check the
current working directory — you may already be inside it), you can read pages
directly as Markdown files using Glob, Grep, and Read. This bypasses both MCP
and CLI entirely and needs no configuration. Slugs map to file paths by
appending `.md` — e.g. `Guides/Deploy-Process` becomes
`Guides/Deploy-Process.md`.

## Workflow

### When to search automatically vs. ask first

Minimize wasted round-trips while avoiding unnecessary searches.

**Default: search.** A quick search that finds nothing costs little; missing a
runbook costs real time. Only ask first when the topic is genuinely ambiguous.

- **Search automatically**: explicit wiki/runbook/ADR request, or clearly about
  an internal process, convention, or architectural decision.
- **Ask first** ("Might be in the wiki — want me to check?"): could be answered
  by vendor docs *or* internal docs and you can't tell which (e.g. "how do I set
  up Redis" — generic setup vs. the team's specific Redis conventions).

### Step 1: Find the page

Determine what the user wants: a specific page (by slug, name, or identifier), a
topic search, or an enumeration of what exists.

**Slug already known** (user pasted it or you recall it) — go straight to Step
2.

**Searching by keyword or topic:**

Start with 1-2 broad searches. If they return promising results, refine with a
narrower query. If 2-3 different search angles all return nothing relevant, the
topic is likely not documented in the wiki — say so and move on rather than
exhaustively trying variations. Fetching a full page via CLI is worthwhile when
MCP snippets look relevant but incomplete; skip it when the snippets already
answer the question.

Follow the fallback chain from **Choosing your tools** (MCP → CLI → local). Key
notes:

- **MCP:** if snippets already answer the question, skip Step 2 and go to Step
  3.
- **CLI list:** always pass `--per-page 100` — the default of 20 truncates most
  wikis:

  ```bash
  gitlab -o 'json' group-wiki list --group-id '<numeric-id>' --per-page '100'
  gitlab -o 'json' project-wiki list --project-id '<numeric-id>' --per-page '100'
  ```

  Each entry has `slug` and `title`. Match loosely against the user's query.

- **Local:** Glob for `**/*keyword*` or `**/*.md`, Grep content, Read matching
  files.

**Browsing / enumeration** (user wants to see what exists): list pages via CLI
or Glob the local checkout, then present a concise numbered summary of titles so
the user can pick.

**Multiple matches?** Present a numbered list with titles and a one-line
description (from the slug or first sentence if available) so the user can
choose, rather than dumping raw JSON.

### Step 2: Fetch the full page

**Via CLI:**

```bash
# Group wiki
gitlab -o 'json' group-wiki get --group-id '<numeric-id>' --slug '<slug>'

# Project wiki
gitlab -o 'json' project-wiki get --project-id '<numeric-id>' --slug '<slug>'
```

Pass the slug as-is (e.g. `Guides/Deploy-Process`) — python-gitlab handles URL
encoding.
The response is a JSON object; extract the `content` field for the Markdown
body.

**Via local checkout:** Read the file directly — the slug plus `.md` is the file
path.

### Step 3: Present the content

- **Specific question**: summarize and quote the relevant sections — don't dump
  the entire page if the user asked about one aspect.
- **Full page request**: render the Markdown.
- **Always mention linked wiki pages** so the user knows they can ask for
  follow-ups.

### Step 4: Anchor this knowledge so future sessions don't miss it

After any lookup — successful or partial — check whether the project's CLAUDE.md
already points to this wiki content. If it doesn't, draft a concrete addition
and offer it.

**Why this matters:** agents naturally gravitate toward local code. Without an
explicit instruction in CLAUDE.md, future sessions will likely skip the wiki on
the same topic. A one-line note fixes this permanently.

**Draft the addition first, then ask.** Don't ask abstractly — show exactly what
would be added:

> This wasn't obvious from the code — I found it in the wiki. Want me to add
> this to CLAUDE.md so future sessions check there automatically?
>
> ```markdown
> # Conventions
>
> Before modifying <topic>, check the wiki first (use gitlab-wiki-lookup).
> Relevant page: <slug>
> ```

Tailor the instruction to the topic: deployment steps, schema migrations, naming
conventions, and similar process-heavy areas are the strongest candidates.

**Also suggest CONTRIBUTING.md** when the wiki content is useful to human
contributors (not just to AI agents) — link the relevant page so teammates can
find it directly.

Only offer each suggestion once. If the user declines, move on.

## Looking up group or project IDs

The CLI requires numeric IDs. If you only have the path (from auto-detection or
the user), look it up:

```bash
gitlab -o 'json' group get --id '<group-path>'
gitlab -o 'json' project get --id '<project-path>'
```

The `id` field in the JSON response is the numeric ID. Cache it for the session
— you will need it for subsequent list/get calls.

If the path lookup fails (404), the user may have given an ambiguous name rather
than a full path. Fall back to a search:

```bash
gitlab -o 'json' group list --search '<name>'
gitlab -o 'json' project list --search '<name>'
```

If multiple results match, present a short list and ask the user which one they
meant.

## Error handling

| Error                                        | Likely cause                  | Fix                                              |
| -------------------------------------------- | ----------------------------- | ------------------------------------------------ |
| `No config file found` / `permission denied` | Missing or unreachable config | Read `setup.md`                                  |
| 404 on page fetch                            | Wrong slug                    | Re-search or list pages to find the correct slug |
| 403                                          | PAT missing `read_api` scope  | Regenerate token with the `read_api` scope       |
| `gitlab: command not found`                  | CLI not installed             | `pipx install python-gitlab`                     |
