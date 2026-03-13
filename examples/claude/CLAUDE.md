# CLAUDE.md

> [!important] Claude Code self-reminders — MANDATORY, follow for every change
>
> 1. **Before making or suggesting any changes, read `CONTRIBUTING.md`**. Pay extra attention to the code organization
>    and conventions.
> 1. **Follow closely the workflow in `CONTRIBUTING.md § Submitting changes`**.
> 1. **Review and offer to update `CONTRIBUTING.md`** to share _relevant_ notes and findings with the team. Insist on
>    this if you make changes.
> 1. **Review and offer to update `CLAUDE.md`** with relevant information _for you_ that would not duplicate the content
>    of `CONTRIBUTING.md`.

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
