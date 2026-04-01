# GitLab Wiki — Setup

Configure `python-gitlab` so the `gitlab` CLI can authenticate to your GitLab instance.

**Option A — Project-local config (recommended; no sandbox override needed):**

Create `.python-gitlab.cfg` in your project root. Add it to your `.gitignore` to avoid
committing credentials:

```ini
[global]
default = example-org

[example-org]
url = https://gitlab.example.org
private_token = <your-read_api-PAT>
api_version = 4
```

Point Claude Code to it via `settings.local.json`:

```json
{
  "env": {
    "PYTHON_GITLAB_CFG": "/Users/<username>/path/to/repo/.python-gitlab.cfg"
  }
}
```

Alternatively, pass the config file directly to each command using `--config-file` (or `-c`):

```bash
gitlab --config-file '.python-gitlab.cfg' -o 'json' group-wiki list ...
```

**Option B — Global config with sandbox allowlist:**

Same INI content at `~/.python-gitlab.cfg`. Grant the sandbox read access to that specific path
— no env var needed, python-gitlab finds it automatically:

```json
{
  "sandbox": {
    "filesystem": {
      "allowRead": ["/Users/<username>/.python-gitlab.cfg"]
    }
  }
}
```

This is cleaner than `dangerouslyDisableSandbox: true` (which disables all sandboxing).

**Option C — Last resort:**

Add `dangerouslyDisableSandbox: true` to each `gitlab` Bash call. Avoids any config changes
but disables the full sandbox for those calls.
