---
name: aws
description: >-
  Invoke this skill whenever the task requires reading from or writing to a
  real AWS account — you have no live infrastructure access without it. This
  covers the full range of operational requests: investigating an incident,
  diagnosing errors or slow performance, checking resource health, scaling
  services, rotating credentials, updating routing rules, querying logs, and
  any other hands-on infrastructure action. Invoke even when "AWS" is never
  mentioned — requests like "the deployment is stuck", "api is throwing 503s",
  "check the metrics", "scale the service", or "add a rule to the listener"
  all imply live account access. Do not invoke for writing AWS SDK code without
  account interaction, explaining how services work conceptually, or comparing
  cloud providers.
argument-hint: >-
  <describe the AWS task, e.g. "list ECS services in prod" or "scale the api
  service to 6 tasks">
---

# AWS Operations

**Request:** $ARGUMENTS

Two AWS agents are available. Route this request to the right one and
orchestrate the result.

## Choosing the right agent

**`aws-operator-ro`** — the default. It runs on a fast, cheap model and is
constrained to read-only operations at the server level, making it the safe
choice for anything where a write isn't explicitly needed. Use it when the
request is clearly read-only (list, describe, inspect, view logs) or when
you're not sure whether a write will be needed.

**`aws-infra-operator-rw`** — use when a write is explicitly requested or
confirmed necessary. It runs on a stronger model, requires mutation consent
before executing changes, and uses a dedicated AWS profile with write
permissions. It also has full read access, so once you're on the write path,
handle any preceding reads here too — no need to split.

## Handling the request

**Write explicitly requested** (create, update, delete, terminate, modify,
rotate credentials, change configuration): Dispatch `aws-infra-operator-rw`
directly.

**Read-only or ambiguous**: Dispatch `aws-operator-ro` first.
After it responds:

- Result fully answers the request → present findings and stop.
- Result reveals a write is needed → report findings to the user, explain
  what action would address the issue, and ask whether to proceed.
  Infrastructure changes are hard to reverse — surface the information and let
  the user decide consciously before dispatching `aws-infra-operator-rw`.

## Multi-step workflows

For workflows with multiple sequential writes, or where order matters (e.g.
create key → update secret → delete old key), don't hand the entire sequence
to the agent at once. Changes can fail partway through, and recovery is much
easier when you've tracked what succeeded.

- Dispatch one step at a time and assess the result before continuing
- Use `SendMessage` to continue an existing agent session rather than spawning
  a new agent for each step — this preserves context and avoids redundant setup
- For high-blast-radius steps (deleting resources, shifting traffic, modifying
  IAM policies): confirm target and scope with the user before dispatching

## Presenting results

Summarize clearly — don't return raw JSON. Extract what matters and present it
in plain language. For multi-step operations, report what completed after each
step before continuing.
