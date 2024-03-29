# Pre-commit

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Local hooks](#local-hooks)
1. [Troubleshooting](#troubleshooting)
   1. [Some files are skipped during a run](#some-files-are-skipped-during-a-run)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Install.
pip install --user 'pre-commit'  # has currently issues with `pipx`
brew install 'pre-commit'

# Generate a very basic configuration.
pre-commit sample-config > '.pre-commit-config.yaml'

# Manually run checks.
pre-commit run --all-files
pre-commit run "ansible-lint" --files "ansible/"

# Automatically run checks at every commit.
pre-commit install

# Update all hooks to the latest version available.
# It is *not* always the latest *stable* release.
pre-commit autoupdate

# Skip checks on commit.
SKIP="check_id" git commit -m "foo"
git commit --no-verify -m "foo"
```

[Config file example].

## Local hooks

```yml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: do-something-with-make-once
        name: Do something with GNU Make once
        language: system
        entry: make do-something
        pass_filenames: false
        require_serial: true
      - id: call-script-passing-files
        name: Call a local script passing files as arguments
        language: script
        entry: path/to/script.sh
```

## Troubleshooting

### Some files are skipped during a run

Check they are tracked (have been `add`ed to the repository).

## Further readings

- Pre-commit's [website]
- List of [supported hooks]

<!--
  References
  -->

<!-- Knowledge base -->
[lefthook]: lefthook.md

<!-- Upstream -->
[file types by extension]: https://github.com/pre-commit/identify/blob/main/identify/extensions.py
[supported hooks]: https://pre-commit.com/hooks.html
[website]: https://pre-commit.com

<!-- Files -->
[config file example]: ../examples/dotfiles/.pre-commit-config.yaml
