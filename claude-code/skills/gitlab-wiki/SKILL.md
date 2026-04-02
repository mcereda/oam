---
name: gitlab-wiki
description: >-
  Propose searching GitLab wikis, runbooks, and ADRs when the answer likely
  lives in internal documentation rather than in code. ALWAYS use this skill
  when the user asks "why" something is done a particular way — why a technology
  was chosen, why a config value is set to a specific number, why an
  architectural pattern is used, or what reasoning drove a design decision.
  These "why" questions about design intent are almost always answered in wikis
  and ADRs, not in code comments. Make sure to also use this skill for
  company-specific "how do I" questions about internal processes (deploying to
  production, onboarding new services, following team conventions), and whenever
  the user explicitly mentions wikis, runbooks, ADRs, or knowledge bases. This
  skill proposes a wiki search to the user rather than searching automatically.
  Do not use for debugging runtime errors, CI failures, code-level questions,
  or general open-source tool usage.
argument-hint: 'what to look up, e.g. "search for deploy guide in project wiki"'
---

# GitLab Wiki Reader

Read wiki pages from a GitLab instance using whichever tools are available.

**Request:** $ARGUMENTS

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

- **Group path**: drop the last segment (e.g. `group/subgroup/project` → `group/subgroup`)
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

Look through your available tools for any GitLab-related MCP server. The tool
prefix varies by configuration — it might be `mcp__plugin_gitlab_gitlab__`,
`mcp__gitlab__`, or something else. What matters is finding a **search** tool
that accepts a `scope` parameter supporting `wiki_blobs`.

To search wiki content via MCP:

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
`No config file found` or `permission denied`, read `references/setup.md` in
this skill's directory for setup instructions and walk the user through it.

### Local checkout (last resort, but fast)

GitLab wikis are git repositories. If the wiki is cloned locally (check the
current working directory — you may already be inside it), you can read pages
directly as Markdown files using Glob, Grep, and Read. This bypasses both MCP
and CLI entirely and needs no configuration. Slugs map to file paths by
appending `.md` — e.g. `Guides/Deploy-Process` becomes
`Guides/Deploy-Process.md`.

## Workflow

### Is this an implicit trigger? Decide first, then suggest

Three types of questions warrant a wiki check even without an explicit mention:

1. **"Why" questions about design intent** — "why does X use Y", "why is this
   configured this way". The code shows _what_ exists; the documentation and/or
   the wiki explain _why_ it was chosen.
2. **Company-specific "how do I" questions** — "how do I add a service to our
   cluster", "what's our process for deploying". The discriminator: does the
   question need _our_ answer (company context → wiki) or a general answer
   (vendor docs → internet)? Qualifiers like "in our setup", "our process",
   "in our environment" signal company context.
3. **Explicit wiki/runbook/ADR requests** — proceed directly without suggesting.

For types 1 and 2: **do not search automatically**. Prompt the user first:

> "This might be documented in the wiki — want me to check?"

Wait for confirmation before running any queries. This keeps interactions
lightweight when the user may already have the context or just wants a quick
answer.

### Step 1: Find the page

Determine what the user wants: a specific page (by slug, name, or identifier), a
topic search, or an enumeration of what exists.

**Slug already known** (user pasted it or you recall it) — go straight to Step
2.

**Searching by keyword or topic:**

1. Try MCP search first (if available):

   ```plaintext
   search(scope="wiki_blobs", search="<query>", group_id="<detected-group-path>")
   ```

   Examine the results. If the content snippets already answer the user's
   question, skip Step 2 and go to Step 3.

2. If MCP is unavailable or returns nothing useful, try the CLI — list all pages
   and match locally:

   ```bash
   # Default page limit is 20, which truncates most wikis — always use --per-page
   gitlab -o 'json' group-wiki list --group-id '<numeric-id>' --per-page '100'
   # or for project wikis:
   gitlab -o 'json' project-wiki list --project-id '<numeric-id>' --per-page '100'
   ```

   Each entry has `slug` and `title`. Match loosely against the user's query.

3. If the CLI also fails (sandbox, missing config), check whether the wiki is
   cloned locally. Use Glob to find pages (e.g. `**/*keyword*` or `**/*.md`) and
   Grep to search content. Read matching files directly.

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
encoding. The response is a JSON object; extract the `content` field for the
Markdown body.

**Via local checkout:** Read the file directly — the slug plus `.md` is the file
path.

### Step 3: Present the content

- **Specific question**: summarize and quote the relevant sections — don't dump
  the entire page if the user asked about one aspect.
- **Full page request**: render the Markdown.
- **Always mention linked wiki pages** so the user knows they can ask for
  follow-ups.

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
| `No config file found` / `permission denied` | Missing or unreachable config | Read `references/setup.md`                       |
| 404 on page fetch                            | Wrong slug                    | Re-search or list pages to find the correct slug |
| 403                                          | PAT missing `read_api` scope  | Regenerate token with the `read_api` scope       |
| `gitlab: command not found`                  | CLI not installed             | `pipx install python-gitlab`                     |
