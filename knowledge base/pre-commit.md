# Pre-commit

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Troubleshooting](#troubleshooting)
   1. [Some files are skipped during a run](#some-files-are-skipped-during-a-run)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Generate a very basic configuration.
pre-commit sample-config > .pre-commit-config.yaml

# Manually run checks.
pre-commit run --all-files
pre-commit run "ansible-lint" --files "ansible/"

# Automatically run checks at every commit.
pre-commit install

# Update all hooks to the latest version available.
# It is *not* always the latest *stable* release.
pre-commit autoupdate

# Skip check on commit.
SKIP="check_id" git commit -m "foo"
```

[Config file example].

## Troubleshooting

### Some files are skipped during a run

Check they are tracked (have been `add`ed to the repository).

## Further readings

- Pre-commit's [website]
- List of [supported hooks]

<!--
  References
  -->

<!-- Upstream -->
[file types by extension]: https://github.com/pre-commit/identify/blob/main/identify/extensions.py
[supported hooks]: https://pre-commit.com/hooks.html
[website]: https://pre-commit.com

<!-- Files -->
[config file example]: ../examples/dotfiles/.pre-commit-config.yaml
