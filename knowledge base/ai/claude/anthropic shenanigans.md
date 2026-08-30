# Anthropic practices

Documented patterns of Anthropic practices that affect users of Claude products.

1. [Feature gating behind telemetry](#feature-gating-behind-telemetry)
1. [Billing and subscription practices](#billing-and-subscription-practices)
1. [Other incidents](#other-incidents)
1. [Mitigations](#mitigations)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Feature gating behind telemetry

Claude Code gates features behind a feature-flag evaluation system that depends on telemetry being enabled.<br/>
Setting **any** of `DISABLE_TELEMETRY=1`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`, `DO_NOT_TRACK=1`, or
`DISABLE_GROWTHBOOK=1` **silently** disables feature-flag evaluation, which in turn silently disables **every** feature
gated behind it.

Claude Code gives **no** warning about this. The features simply do not load.<br/>
Tools that depend on a flag (e.g. `ListAgents` for [cross-session messaging][claude code / cross-session messaging]) are
**hidden** from any session. The user sees **no** error, **no** degradation notice, **nothing**. Commands (e.g.,
`/list-agents`) and tools that should exist simply do not exist in the session.

> [!important] The sessions' scope is affected
> The environment variables can come from a shell variable, a `settings.json` at **any** scope (`settings.local.json`
> included), or managed settings.<br/>
> A project-level `settings.json` file setting `DISABLE_TELEMETRY=1` disables gated features for **all** sessions in
> that project, even if the user's global settings leave telemetry enabled.

The practical consequence is that exercising the documented privacy control (disabling telemetry) silently degrades
the product.<br/>
Users are **not** informed of this tradeoff when setting the variable, and Anthropic's own documentation recommends
checking `/list-agents` only **after** the feature fails to work.

As of 2026-08, the known tools and features gated behind feature-flag evaluation include:

- [Cross-session messaging][claude code / cross-session messaging] (`ListAgents`, `SendMessage`)
- Push notifications (`PushNotification`)
- Remote routine triggers (`RemoteTrigger`)
- Background event streaming (`Monitor`)

The mechanism is general. Any future feature behind a flag will also be dark when telemetry is disabled.

## Billing and subscription practices

Anthropic has a track record of making significant billing changes with little or no notice or transparency, including
the consistent pattern of moving capabilities that were part of the subscription behind separate billing walls **after**
users have built workflows around them.

In the span of six weeks (April to May 2026), Anthropic:

1. Banned third-party agents (e.g. OpenClaw) from using subscriptions, limiting them to API-only billing.
1. Temporarily removed [Claude Code] from the Pro subscription tier, then claimed it was a test when users objected.
1. Announced that non-interactive usage (headless `claude -p`, the Agent SDK), previously covered by subscriptions,
   would draw from a separate, capped Agent SDK credit pool at full API rates, presenting this like it was a _gift_ and
   not a new limitation.<br/>
   This was _suspended_ (but **not** _discarded_ at the time of writing) when the community backlashed.

   The proposed credit pool caps were:

   | Plan          | Monthly Agent SDK credit |
   | ------------- | -----------------------: |
   | Pro           |                      $20 |
   | Max 5x        |                     $100 |
   | Max 20x       |                     $200 |
   | Team Standard |                 $20/seat |
   | Team Premium  |                $100/seat |

   Credits would not roll over. Once exhausted, invocations would be billed as "extra usage" at standard API rates (if
   enabled), or stop entirely.

Anthropic also introduced a new tokenizer with Opus 4.7 that inflated token counts for English conversations by ~1.4
times. Pricing per token was unchanged.<br/>
English-dominant workloads started costing ~35 to 45% more, **and** caused a reduced effective context window capacity
in the process.

## Other incidents

In 2026, Anthropic silently built a system to detect when Claude Code users were running third-party agent harnesses
(e.g. [Hermes Agent][NousResearch/hermes-agent], OpenClaw), and **silently** charged them API rates instead of
subscription rates when detected.<br/>
This went undiscovered until users noticed unexplained extra-usage charges on Max plans despite low dashboard
utilization. Tests showed that even an empty repository with "OpenClaw" in a JSON blob triggered the detection.<br/>
The incident surfaced through viral posts before Anthropic acknowledged it publicly.

In March 2026, after a packaging error exposed Claude Code's source code, an overly broad DMCA takedown cascaded to
~8,100 forks of the original GitHub repositories.

Anthropic changed documentation or pricing multiple times **without** any public announcement.

## Mitigations

For **billing**, treat any subscription-covered automation as a **convenience** that will be further restricted or
repriced.<br/>
Consider design launchers with a local LLM fallback (e.g. via [Ollama]) for non-critical automation.

For **telemetry gating**, accept the tradeoff (telemetry on = full features) or accept the degradation (telemetry off =
some features silently missing). There is no middle ground as of 2026-08.

Pin model versions.

Monitor the [community tracker][clawd.rip] for emerging issues.

## Further readings

- [Claude]
- [Claude Code]
- [Everything that went/is wrong with Claude][clawd.rip]

### Sources

- [Cross-session messaging documentation]
- [Anthropic's OpenClaw and Hermes Detection Controversy]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Claude Code / Cross-session messaging]: claude%20code.md#cross-session-messaging
[Claude Code]: claude%20code.md
[Claude]: README.md
[Ollama]: ../ollama.md

<!-- Upstream -->
[Cross-session messaging documentation]: https://code.claude.com/docs/en/cross-session-messaging

<!-- Others -->
[Anthropic's OpenClaw and Hermes Detection Controversy]: https://www.mindstudio.ai/blog/anthropic-openclaw-hermes-detection-controversy-claude-max
[clawd.rip]: https://clawd.rip/
[NousResearch/hermes-agent]: https://github.com/NousResearch/hermes-agent
