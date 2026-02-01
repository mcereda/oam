# GitLab CLI

The `glab` utility is a CLI tool for GitLab.

Available for repositories hosted on GitLab.com, GitLab Dedicated, and GitLab Self-Managed.<br/>
Supports multiple authenticated GitLab instances.<br/>
Automatically detects the authenticated hostname from the remotes available in one's working Git directory.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install.
brew install 'glab'

# Start interactive configuration.
glab auth login

# Load shell completions.
glab completion -s 'fish' > "$HOME/.config/fish/completions/glab.fish"
source <(glab completion -s 'bash')
```

Global configuration file: `~/.config/glab-cli/config.yml`.<br/>
Repository-specific configuration file: `.git/glab-cli/config.yml`<br/>
They contain tokens in plaintext.

</details>

<details>
  <summary>Usage</summary>

```sh
# Get help.
glab --help
glab user --help
glab release view --help

# Make changes to the configuration.
glab config edit
glab config edit --local
glab config set 'host' 'gitlab.example.org' --global
glab config set 'git_protocol' 'ssh' --host 'gitlab.example.org'
glab config set 'api_protocol' 'https' -h 'gitlab.example.org'
glab config set 'editor' 'vim'
glab config set 'token' 'xxxxx' -h 'gitlab.com'
glab config set 'check_update' 'false' --global

# Get repositories' information.
glab repo view 'someGroup/someRepo' -F 'json'

# Clone repositories.
glab repo clone 'someGroup/someRepo'

# List issues.
glab issue list
glab issue list --repo 'someGroup/someNamespace/someRepo'

# List Merge Requests.
glab mr list
glab mr list --repo 'someGroup/someNamespace/someRepo'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Codebase]
- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Codebase]: https://gitlab.com/gitlab-org/cli
[Documentation]: https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/index.md

<!-- Others -->
