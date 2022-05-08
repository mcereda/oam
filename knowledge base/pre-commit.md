# Pre-commit

## TL;DR

```shell
# generate a very basic configuration
pre-commit sample-config > .pre-commit-config.yaml

# manually run checks
pre-commit run --all-files
pre-commit run ansible-lint --files ansible/

# automatically run checks at every commit
pre-commit install

# update all hooks to the latest version
pre-commit autoupdate

# skip check on commit
SKIP=flake8 git commit -m "foo"
```

```yaml
---
# File .pre-commit-config.yaml
# See https://pre-commit.com for more information
# See https://pre-commit.com/hooks.html for more hooks

repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.2.0
    hooks:
      - id: trailing-whitespace
        args:
          - --markdown-linebreak-ext=md   # ignore markdown's line break
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
  - repo: https://github.com/markdownlint/markdownlint
    rev: v0.11.0
    hooks:
      - id: markdownlint
        args:
          - -r "~MD013"                   # ignore line-length rule
  - repo: https://github.com/ansible-community/ansible-lint
    rev: v6.0.2
    hooks:
      - id: ansible-lint
```

## Further readings

- Pre-commit's [website]
- List of [supported hooks]

[supported hooks]: https://pre-commit.com/hooks.html
[website]: https://pre-commit.com
