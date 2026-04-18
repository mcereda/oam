# Architectural decision records

1. [TL;DR](#tldr)
1. [Status](#status)
1. [Lifecycle relationships](#lifecycle-relationships)
1. [Title conventions](#title-conventions)
1. [Body conventions](#body-conventions)
1. [Scope](#scope)
1. [Triggers for revisiting](#triggers-for-revisiting)
1. [Indexes](#indexes)
1. [Metadata vs body](#metadata-vs-body)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

_Architectural Decisions_ (ADs) are justified design choices, addressing functional or non-functional requirements that
are architecturally significant.

_Architecturally Significant Requirements_ (ASRs) are requirements that has a measurable effect on the architecture, and
quality of a software and/or hardware system.

_Architectural Decision Records_ (ADRs) capture a single AD and its rationale.<br/>
ADR are meant to help one understand the reasons for a chosen architectural decision, along with its trade-offs and
consequences.

The collection of ADRs that are created and maintained in a project constitute its decision log.<br/>
All these are within the topic of Architectural Knowledge Management (AKM), but ADR usage can be extended to design and
other decisions (_any decision record_).

Each ADR should have:

- A clear [status], e.g. _proposed_, _accepted_, _rejected_.<br/>
  Readers scanning the index should be able to tell at a glance which ADRs are awaiting decisions versus which have been
  decided to defer or to be avoided.
- Clear [references to others][lifecycle relationships], if relevant.<br/>
  Readers who open the deferred ADR should notice that it was deferred by another ADR **without** having to find that
  other one first. Same the other way.
- A clear [title][title conventions].<br/>
  Readers should be able to _predict_ the gist of the body from the title alone.
- A clear [body][body conventions].
- **One** clear [scope].

## Status

Refer to [Michael Nygard's original essay][Documenting Architecture Decisions] and [MADR][madr].

The following is a minimal, useful set of statuses:

| Status     | Meaning                                                                            |
| ---------- | ---------------------------------------------------------------------------------- |
| Proposed   | Draft, awaiting review. Not yet authoritative.                                     |
| Accepted   | Reviewed and adopted. Currently authoritative.                                     |
| Deferred   | Reviewed but not adopted now. Idea still valid; timing is wrong. May be revisited. |
| Superseded | Replaced by a newer ADR. The newer one is the authoritative source.                |
| Rejected   | Reviewed and not adopted. The idea was found unsound. Use sparingly.               |

Statuses might feel similar, but do have important distinction between them. E.g., _proposed_ implies the review has
**not** happened yet, while _deferred_ means the review happened and was decided to take action _in the future™_.

## Lifecycle relationships

When ADRs relate to each other, also encode the relationship in metadata, not just in the text.<br/>
Prefer using **symmetric** pairs for **each** document:

| Pair                           | Meaning                                                          |
| ------------------------------ | ---------------------------------------------------------------- |
| `Supersedes` / `Superseded by` | One ADR _replaces_ another. The old ADR is now historical.       |
| `Defers` / `Deferred by`       | One ADR _ratifies_ the status quo, deferring another's proposal. |
| `Refines` / `Refined by`       | One ADR _adds details_ to another's broad direction.             |

<details>
  <summary>Example metadata</summary>

```md
| **Status**      | Deferred                                                |
| **Deferred by** | [ADR 0007 - Ratify current IaC code location practices] |
```

```md
| **Status** | Accepted                                                      |
| **Defers** | [ADR 0006 - Distribute IaC ownership to service repositories] |
```

</details>

## Title conventions

Titles set expectations.

Two shapes have been commonly used:

- **Verb + object** (e.g., `Standardize naming`, `Distribute IaC`, `Adopt KMS`): works well for action-oriented ADRs.
- **Noun phrase** (e.g., `ALBs for service exposure`, `Internal ALB for private services`): works well for ADRs that
  document a chosen pattern or internal convention.

When used, a verb should match the _strength_ of the change:

| Verb                                        | Implies                                                                 |
| ------------------------------------------- | ----------------------------------------------------------------------- |
| _Standardize_, _Document_                   | Codifying or formalizing _existing_ practice                            |
| _Adopt_                                     | Bringing in something new, but **not** reorganizing what already exists |
| _Distribute_, _Decentralize_, _Consolidate_ | Restructuring (changing where things live)                              |
| _Migrate_, _Move_                           | Explicit _transitions_ with a before and an after state                 |
| _Ratify_                                    | Formal acceptance of _current_ state, often paired with a deference     |

An ADR titled _Standardize_, but proposing restructuring, is misleading.<br/>
Match the verb to the actual decision.

## Body conventions

Sections that earn their place in _most_ ADRs:

1. **Context**: what's true today, what problem prompts the decision.<br/>
   Should ground a reader who has no prior context.
1. **Decision**: the actual decision, in imperative voice.<br/>
   The first sentence should be the answer to the question implicit in the title.
1. **Alternatives considered**: other options examined, why they were not chosen.<br/>
   Even the rejected alternatives belong here so the reasoning isn't lost.
1. **Consequences**: what changes, what costs, what new commitments the decision creates.

Optional but useful:

1. **Migration**: for restructuring decisions: how to get from current to chosen state.<br/>
   Often just a link to a runbook elsewhere.
1. **What this ADR does not do**: see the [Scope] section.
1. **Further reading**: links to background, source material, related ADRs.

## Scope

A.K.A _What this ADR does **not** do_.

For decisions that ratify current practice or defer a proposal, an explicit _"What this ADR does not do"_ section is
valuable. It surfaces the _accepted_ non-changes, and prevents future readers from assuming the ADR resolved things it
didn't.

For example, if an ADR ratifies a current naming inconsistency without forcing a fix, naming the inconsistency in the
body keeps the choice visible rather than implicitly endorsing it as correct.<br/>
A future engineer reading the ADR knows the inconsistency was _seen_, not _overlooked_.

## Triggers for revisiting

List the concrete conditions that would warrant revisiting deferred (or _temporary™_) decisions.<br/>
Without explicit triggers, the conversation re-starts from scratch every time someone wonders if it's time.

<details style='padding: 0 0 1rem 1rem'>
  </summary>Example phrasing</summary>

> Triggers that would warrant revisiting \[ADR-XXXX]:
>
> - The stack's complexity grows to the point where recovering the state during incidents materially impacts application
>   availability or engineering time.
> - More services emerge whose IaC lives outside the monorepo, making the ad hoc split harder to reason about.

</details>

A revisit conversation can then start with _"has X happened yet?"_ rather than re-litigating the original trade-offs.

## Indexes

A separate `ADRs.md` (or equivalent) index file should be created once past 5-10 ADRs.

It can just be a table. In this case, keep the columns minimal and stable, e.g., _number_, _title_, _summary_, _status_.

The index only needs to link to the ADRs.<br/>
When a deferred ADR points to a ratifying one, the relationship is in the deferred ADR's metadata; the index should just
show _Deferred_, and **optionally** the number of the ADR that next addresses the issue.

## Metadata vs body

Metadata carries **structure**, the body carries the **rationale**.

- Status, dates, authors, lifecycle relationships should be added to the metadata's table.
- _Why_ the decision was made, why alternatives were rejected, _how_ to revisit a decision should be included in the
  ADR's body.

Putting rationale in the metadata makes it long, and harder to scan. Burying structural relationships in text makes it
hard to find when traversing a graph of ADRs.

## Further readings

- [Website]
- [Codebase]
- [Amazon's ADR process]
- [straw-hat-team/adr]
- [Love Unrequited: The Story of Architecture, Agile, and How Architecture Decision Records Brought Them Together]
- [Azure Well-Architected Framework]
- [Documenting Architecture Decisions]
- [MADR]

### Sources

- [Documenting Architecture Decisions]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Body conventions]: #body-conventions
[Lifecycle relationships]: #lifecycle-relationships
[Scope]: #scope
[Status]: #status
[Title conventions]: #title-conventions

<!-- Upstream -->
[Codebase]: https://github.com/joelparkerhenderson/architecture-decision-record
[Website]: https://adr.github.io/

<!-- Others -->
[Amazon's ADR process]: https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html
[Azure Well-Architected Framework]: https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-decision-record
[Documenting Architecture Decisions]: https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
[Love Unrequited: The Story of Architecture, Agile, and How Architecture Decision Records Brought Them Together]: https://ieeexplore.ieee.org/document/9801811
[MADR]: https://adr.github.io/madr/
[straw-hat-team/adr]: https://github.com/straw-hat-team/adr
