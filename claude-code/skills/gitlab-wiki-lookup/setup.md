# GitLab Wiki — First-Run Setup

The `gitlab` CLI (python-gitlab) needs a configuration file to connect. Choose one of
these options:

## Option A — Project-local config (recommended)

No sandbox override needed. Create `.python-gitlab.cfg` in the project root (add it to
`.gitignore` if it is not already there):

```ini
[global]
default = example_org

[example_org]
url = https://gitlab.example.org
private_token = <your-gitlab-PAT-here>
api_version = 4
```

Then point Claude Code at it via `settings.local.json`:

```json
{
  "env": {
    "PYTHON_GITLAB_CFG": "<absolute-path-to>/.python-gitlab.cfg"
  }
}
```

## Option B — Global config with sandbox allowlist

Same INI content at `~/.python-gitlab.cfg`. Grant the sandbox read access to that path:

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

Add `dangerouslyDisableSandbox: true` to each `gitlab` Bash call. Avoids config changes
but disables the full sandbox for those calls.

## Verifying

```bash
# Replace <group-or-project-name> with something you expect to find
gitlab -o 'json' group list --search '<group-or-project-name>'
```

Should return at least one result. If you get `No config file found`, double-check the
file path and env var.
