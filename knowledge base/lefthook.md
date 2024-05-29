# Lefthook

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
   1. [Extend other files](#extend-other-files)
   1. [Use files from other repositories](#use-files-from-other-repositories)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Installation.
go install 'github.com/evilmartians/lefthook@latest'
npm install 'lefthook' --save-dev
gem install 'lefthook'
brew install 'lefthook'

# Get help about any command.
lefthook help
lefthook help 'dump'

# Generate autocompletion scripts for the specified shells.
lefthook completion 'zsh'
lefthook completion -v 'fish' > "$HOME/.config/fish/completions/lefthook.fish"
source <(lefthook completion 'bash')

# Add configured hooks to the current git repository.
# Creates a basic configuration file in the repository if missing.
lefthook install

# Print the merged configuration from all files.
lefthook dump

# Add hook directories to the current repository.
lefthook add 'pre-commit'
lefthook add -dv 'commit-msg'

# Execute groups of hooks.
lefthook run 'pre-push'
lefthook run -v 'lint' --all-files
lefthook run 'pre-commit' -n --commands 'hadolint' --files 'lefthook.yml'

# Remove configured hooks from the current git repository.
lefthook uninstall
lefthook uninstall -cv

# Reset lefthook-managed git hooks and start from the beginning.
lefthook uninstall && lefthook install

# Disable lefthook for this commit.
LEFTHOOK=0 git commit -am "Lefthook skipped"
LEFTHOOK=false git commit -am "Lefthook skipped"

# Avoid commands and scripts by name or tag for this commit.
LEFTHOOK_EXCLUDE=ruby,security,lint git commit -am "Skip some tag checks"
```

Uses the [glob library] for glob patterns.

## Configuration

Configuration files can be written in JSON, TOML or YAML.<br/>
Only one of them will be used, even if there are more than one in the repository. The chosen one will be the first one
found during initialization, hence it is suggested to use a **single** configuration file in any of the above formats.

The _main_ configuration file must exist and go by the name `lefthook.<formatExtension>` or `.lefthook.<formatExtension>`.

An _extra_ configuration file named `lefthook-local` is merged with the main file if found upon initialization. All
supported formats can be applied to this `-local` file.<br/>
If the main configuration file starts with the leading dot, the `-local` file must also start with the leading dot.

```sh
$ ls -A1 *lefthook*
.lefthook-local.json
.lefthook.yml
```

[Configuration file example]

Configuration files can extend other files recursively.

### Extend other files

```yaml
extends:
  - .lefthook/commitlint.yml
  - .lefthook/docker.yml
  - .lefthook/json.yml
```

### Use files from other repositories

Refer the [configuration] page.

Use the `remotes` key to include configuration files from this repository.<br/>
The configuration from remotes will be merged to the local config using the following priority:

- Local main config (`lefthook.yml`).
- Remote configs (`remotes`).
- Local overrides (`lefthook-local.yml`).

```yaml
# lefthook.yml
lint:
  parallel: true
  commands:
    yaml:
      glob: "*.{yaml,yml}"
      run: >-
        docker run --rm -v "$PWD:/code" 'registry.gitlab.com/pipeline-components/yamllint:latest'
        yamllint {all_files}
remotes:
  - git_url: https://gitlab.com/mine/oam.git
    ref: main
    configs:
      - quality-assurance/lefthook/commitlint.yml
      - quality-assurance/lefthook/docker.yml
      - quality-assurance/lefthook/json.yml
```

```yaml
# lefthook-local.yml
no_tty: false
lint:
  commands:
    yaml:
      run: .venv/bin/yamllint {all_files}
```

```sh
$ lefthook dump
…
lint:
  commands:
    docker:
      run: hadolint {all_files}
      glob: "*[Dd]ockerfile*"
    yaml:
      run: .venv/bin/yamllint {all_files}
      glob: "*.{yaml,yml}"
  parallel: true
```

## Further readings

- [Github]
- [Configuration]
- [Pre-commit]

## Sources

All the references in the [further readings] section, plus the following:

- [Lefthook: knock your team's code back into shape]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[pre-commit]: pre-commit.md

<!-- Files -->
[configuration file example]: ../examples/dotfiles/.lefthook.yml

<!-- Upstream -->
[configuration]: https://github.com/evilmartians/lefthook/blob/master/docs/configuration.md
[github]: https://github.com/evilmartians/lefthook
[lefthook: knock your team's code back into shape]: https://evilmartians.com/chronicles/lefthook-knock-your-teams-code-back-into-shape

<!-- Others -->
[glob library]: https://github.com/gobwas/glob
