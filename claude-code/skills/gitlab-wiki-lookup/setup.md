# GitLab Wiki — First-Run Setup

**Do you need this?** If your Claude Code session has GitLab MCP tools enabled,
the skill can use those instead. Check the available tools in your session — if
you see any `mcp__` tools prefixed with `gitlab` or `plugin_gitlab`, you may
already have access and can skip this setup.

If you don't have MCP tools, the `gitlab` CLI (python-gitlab) is the fallback
option. It needs a configuration file with authentication.

**Why python-gitlab and not glab?** The official GitLab glab CLI doesn't have
wiki page commands. python-gitlab has full wiki support (read, list, fetch
pages), making it the right choice for this skill.

Choose one of these options:

## Before you start: Create a Personal Access Token (PAT)

1. Go to your GitLab instance → **Settings → Access Tokens**
2. Create a new token with **`read_api` scope** (allows reading wiki pages)
3. Copy the token — you'll use it below in the config file
4. **Keep it secret** — treat it like a password

## Option A — Project-local config (recommended)

No sandbox override needed. Create `.python-gitlab.cfg` in the project root:

1. **Create the file** with the config below
2. **Add to `.gitignore`** — this file contains your secret token, so it must
   never be committed to git

```ini
[global]
default = example_org

[example_org]
url = https://gitlab.example.org
private_token = <your-gitlab-PAT-here>
api_version = 4
```

Then point Claude Code at it via `settings.local.json` in your project root:

```json
{
  "env": {
    "PYTHON_GITLAB_CFG": "/absolute/path/to/project/.python-gitlab.cfg"
  }
}
```

Replace `/absolute/path/to/project` with the full path to your project directory
(e.g., `/Users/you/projects/my-repo`). You can find it by running `pwd` in your
project root.

## Option B — Global config with sandbox allowlist

Same INI content at `~/.python-gitlab.cfg`. Grant the sandbox read access to
that path:

```json
{
  "sandbox": {
    "filesystem": {
      "allowRead": ["~/.python-gitlab.cfg"]
    }
  }
}
```

## Option C — Last resort

Add `dangerouslyDisableSandbox: true` to each `gitlab` Bash call. Avoids config
changes but disables the full sandbox for those calls.

## Verifying your setup

Test that the CLI can connect to GitLab:

```bash
gitlab -o 'json' group list --search '<your-group-name>'
```

Replace `<your-group-name>` with a group that exists in your GitLab instance.
You should see at least one result.

**Troubleshooting:**

- `No config file found` → Check file path and `PYTHON_GITLAB_CFG` env var
  (Option A) or `~/.python-gitlab.cfg` (Option B)
- `403 Forbidden` → Your token may not have `read_api` scope. Regenerate it with
  the correct scope
- `404` → The group name doesn't exist or your token can't access it

## Making this skill discoverable to agents

> [!warning] Critical step
> Without explicit instructions in a project's documentation, agents will tend
> to **not** use this skill. They'll default to code search and built-in MCP
> tools instead.

After installing this skill, add reminders in your project:

### In CLAUDE.md

Add a section like:

```markdown
## Wiki Resources

For questions about deployment processes, schema changes, naming conventions,
team procedures, or anything else that's "how we do things here," use the
`gitlab-wiki-lookup` skill to check the wiki first. It's often faster than
searching code, and catches conventions that aren't documented in the
repository.
```

### In CONTRIBUTING.md

Link to specific wiki pages that contributors should check before making
changes:

```markdown
Before making changes:

- **Modifying database schemas**: See the wiki's [Schema Migration Guide](#) for
  our approval and testing process.
- **Creating or modifying services**: Check the wiki's [Service Checklist](#)
  for naming conventions and required configuration.
- **Deployment or release work**: Review [our deployment guide](#) in the wiki
  before proceeding.
```

This guides both human contributors and AI agents to the right resources.
Without these breadcrumbs, agents won't think to use the skill, even when the
answer is in the wiki.
