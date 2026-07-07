# Linear

Project management tool.

1. [TL;DR](#tldr)
1. [Workspaces](#workspaces)
1. [Teams](#teams)
1. [Issues](#issues)
1. [Projects](#projects)
1. [Milestones](#milestones)
1. [Cycles](#cycles)
1. [Initiatives](#initiatives)
1. [Triage](#triage)
1. [Labels and Filtering](#labels-and-filtering)
1. [Integrations](#integrations)
    1. [GitLab](#gitlab)
    1. [Slack](#slack)
1. [Convert an existing issue into a recurring one](#convert-an-existing-issue-into-a-recurring-one)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

Uses keyboard shortcuts extensively.

Single [_workspace_][workspaces] per company. Divides into _teams_. Provides company-wide workflows and templates.

[Teams] contain _issues_ and _projects_. They inherit company-wide workflows and templates and can create their own.

Issues are the basic unit of work. Concrete, self-contained task owned by individuals that might take some amount of
time to complete. Can be templated. Can connect to external documents, GitHub/GitLab pull/merge requests, other links.

Projects are collections of issues. Time bound deliverable that can be worked on across teams. E.g., new app feature, UI
refresh.<br/>
Good place for planning, to draft specifications, and how to go for the goal. Usually contain goals, data, and possible
approaches. Can be the source of truth for a broad task.<br/>
Allows collaboration between users in _threads_. Provides easy conversion of lists into tasks, and of sections into
documents that can be expanded.<br/>
Can automatically post possibly **qualitative** updates to [Slack] channels. E.g., blockers, changes in decisions.

_Milestones_ break projects into different phases. E.g., releases.

_Initiatives_ are collections of projects. Usually tied to top level goals or objectives. Can take quarters to complete.

Lots of filter can help with focus.

Integrations automate common actions. E.g., GitLab's integration automatically adds links to MRs in issues, Slack's
allows automatically sending updates to channels or managing issues from them via slash commands.

_Triage_ is a good place to discuss, accept/refuse, and prepare issues.

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Workspaces

One workspace per company.

Provides company-wide workflows, templates, labels, and integrations.

All [teams], [projects], and [initiatives] for a company live under the same workspace.

## Teams

The primary organizational unit within a [workspace][workspaces].

Each team has its own issue backlog, workflows (state sets), labels, cycles, and triage queue.<br/>
They inherit company-wide workflows and templates, but can also create their own.

[Issues] belong to exactly one team. [Projects] coordinate cross-teams.

Each team has a unique key that becomes the prefix for its issue identifiers (e.g., `XMP-1234`).

## Issues

The atomic unit of work. Concrete, self-contained tasks owned by an individual.

They move through team-defined workflow states (e.g., Backlog → Todo → In Progress → Done → Canceled).<br/>
State transitions can be automated using [integrations] (e.g., GitLab MR merged → Done).

An issue can only belong to one project at a time.<br/>
Sub-issues allow decomposition in multiple children tasks.<br/>
Issues can relate and link to each other.<br/>
Templates can standardize recurring issue types and require basic details.

## Projects

Collections of issues. They represent a time-bound deliverable (e.g., a new feature, a UI refresh, an infrastructure
migration).
_Can_ span multiple [teams]. Each team's issues appear in separate tabs.

They are meant for planning. Their content should hold goals, specifications, data, and approach notes. Also see
[ADR].<br/>
The project lead is the owner. Members collaborate through threaded discussions in the project's body.<br/>
Sections within a project can convert to standalone documents. Lists can convert to issues.

Progress tracking shows completion rates via graphs.<br/>
Start and target dates support different granularity (year, quarter, month, or specific day).<br/>
Projects' status (_planned_, _started_, _paused_, _completed_, _canceled_, …) improves visibility.

If an [integration][integrations] is active, projects can automatically post (possibly) qualitative updates to apps
(e.g., Slack channels) to keep audiences informed. Usually blockers, decisions, and progress.

## Milestones

They break projects into phases, e.g. releases or delivery stages.<br/>
They appear on the project's progress graph and provide intermediate checkpoints within a project's timeline.

## Cycles

Time-boxed iterations for a [team][teams], similar to sprints.

Teams configure cycle duration (typically one or two weeks) and auto-scheduling.<br/>
Issues roll over between cycles automatically when incomplete.<br/>
Cycle analytics track velocity and completion patterns.

Teams can skip cycles and work from a continuous backlog.

## Initiatives

The highest organizational level within a workspace.

Collections of [projects] tied to the company objectives or quarterly goals.<br/>
Can take quarters to complete. They provide visibility across multiple workstreams.

Status indicators (green/yellow/red) show initiatives' health at a glance.
Progress graphs aggregate completion across constituent projects.

They support [labels][labels and filtering] (product line, region, planning period), owners, priority levels, and target
dates.

## Triage

Team-level inbox for incoming issues.

Issues enter triage when they are created by integrations (e.g., Slack, Sentry), just created in the `triage` view, or
submitted by non-team members.

Accepting an issue moves it to the default workflow state.<br/>
Marking it as duplicate merges it into the existing issue.<br/>
Declining it cancels the issue with a comment.<br/>
Snoozing it returns it at a specified time or on new activity.

Teams can assign triage responsibility to specific members or integrate the inbox with on-call scheduling tools
(e.g., PagerDuty, OpsGenie).<br/>
Team settings can require an issue to be assigned a priority before it can leave the triage.

## Labels and Filtering

Flexible tags for categorization (e.g., _bug_, _feature_, teams, components, or any project-specific taxonomy).<br/>
They exist at [workspace][workspaces] and [team][teams] levels.

Views and filters help manage focus.<br/>
Custom views can be saved and shared.

## Integrations

### GitLab

A webhook links merge requests to issues when the MR:

- Includes the issue's ID in the branch name (e.g., `feat/XMP-1234-something`)
- Includes the issue ID directly in the title.
- Uses **magic words** followed by the issue's ID in the description (e.g., _Fixes XMP-1234_).

  "Fixes", "closes", or "resolves" auto-close the issue (if configured to).<br/>
  "Ref", "part of", or "related to" add the link but do not close the issue.

Automatic status updates can track the MR's lifecycle: draft opened → review requested → CI passing → merged.<br/>
Automations are customizable per team and can differ by target branch (e.g., `staging` vs `production` vs `main`).

> [!important]
> Only a single GitLab instance is allowed per workspace.<br/>
> Self-hosted instances must be publicly accessible and v15.6+.

### Slack

Offers multiple entry points for creating issues:

- `@Linear` mentions allow using natural language.
- Message actions (More → Create Issue).
- `/linear` slash command.

Only workspace members with Linear accounts can create issues.

Can send notifications for new issues, status changes, issue activity, and mirror inbox notifications.<br/>
_Synced_ threads keep Slack conversations and Linear comments updated bidirectionally.

Linear can auto-create a public Slack channel per project. When doing it, it can invite all members and bookmark the
project's link.

## Convert an existing issue into a recurring one

This procedure is UI-only (no API support).

1. Open the issue in Linear.
1. Click the `…` menu at the top and choose _Convert into_ > _Recurring issue…_ (or use `Cmd+K` and type "Convert into
   recurring issue").
1. Pick the first due date and the cadence (e.g., every 2 months).

## Further readings

- [Website]
- [Codebase]
- [Blog]
- Alternatives: [Jira]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Initiatives]: #initiatives
[Integrations]: #integrations
[Issues]: #issues
[Labels and filtering]: #labels-and-filtering
[Projects]: #projects
[Teams]: #teams
[Workspaces]: #workspaces

<!-- Knowledge base -->
[ADR]: adr.md
[Jira]: jira.md
[Slack]: slack.md

<!-- Files -->
<!-- Upstream -->
[Blog]: https://linear.app/now/
[Codebase]: https://github.com/linear
[Documentation]: https://linear.app/docs/
[Website]: https://linear.app/

<!-- Others -->
