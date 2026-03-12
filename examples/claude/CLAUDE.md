# CLAUDE.md

> [!important] Claude Code self-reminders — MANDATORY, follow before every change
>
> 1. **Read `CONTRIBUTING.md` at the start of each task** (especially after a git pull), before making any changes.
> 1. **Follow the workflow in `CONTRIBUTING.md § Submitting changes`** (feature branch → run tests → MR → CI → merge).
>    Never apply changes directly; always run tests first and fix all errors.
> 1. **Ask to update `CONTRIBUTING.md`** when the code ends up differing from the instructions it holds.
> 1. **Ask to update this file** (`CLAUDE.md`) before finishing if you discover a new gotcha or convention during the
>    session.

## Overview

Example.org's IaC monorepo using [Pulumi](https://www.pulumi.com/) with Python.\
The S3 backend is at `s3://e-org-infra/`.\
The canonical versions used in CI are defined in `.gitlab-ci.yml`. Check it for the current `pulumi-python` image tag.
Do **not** rely on any version number hardcoded in this file.

See `CONTRIBUTING.md` for everything else: project structure, code organization, code conventions, task commands,
submission workflow, and ownership.

Use this file to store instructions that are absent from `CONTRIBUTING.md`, or to add Claude Code-specific context.

## Claude Code-specific notes

- Always use `non-interactive` commands variants (see `CONTRIBUTING.md § Execution environment`).
  `pulumi update` requires a TTY entirely and cannot be used from Claude Code.
