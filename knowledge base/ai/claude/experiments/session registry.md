# Discovering active sessions

Claude Code maintains a live session registry that any session can read to discover its siblings.

1. [TL;DR](#tldr)
1. [Registry structure](#registry-structure)
   1. [Session files](#session-files)
   1. [IDE lock files](#ide-lock-files)
   1. [Daemon roster](#daemon-roster)
1. [Self-identification](#self-identification)
1. [Stale entry detection](#stale-entry-detection)
1. [Practical value](#practical-value)
1. [Further readings](#further-readings)

## TL;DR

Each running [Claude Code] session registers a JSON file at `~/.claude/sessions/<pid>.json`. The file is removed on
graceful exit. This provides a reliable census of active sessions on the machine, and can be leveraged from sessions to
discover active siblings.

The registry is **read-only** data. A session can consult it to tell who else is there, but provides no communication
channel on its own.<br/>
Sessions can communicate by [making changes to auto-loaded files][propagating knowledge between concurrent sessions]. A
session can discover siblings via the registry, then write targeted memory entries knowing which project scopes will
reach which sessions.

## Registry structure

### Session files

Each file at `~/.claude/sessions/<pid>.json` contains:

```json
{
  "pid": 6719,
  "sessionId": "196377df-3c8f-449c-8ea1-040a5c3b510c",
  "cwd": "/Users/me/some-project",
  "startedAt": 1783368576073,
  "procStart": "Mon Jul  6 20:09:35 2026",
  "version": "2.1.193",
  "peerProtocol": 1,
  "kind": "interactive",
  "entrypoint": "cli",
  "status": "busy",
  "updatedAt": 1783369193375,
  "statusUpdatedAt": 1783369193375
}
```

| Field        | Meaning                                                                                                                               |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| `pid`        | OS process ID; verifiable via `ps -p <pid>`                                                                                           |
| `sessionId`  | UUID correlating with session logs, task directories, and `session-env/`                                                              |
| `cwd`        | Working directory (which project this session is in)                                                                                  |
| `status`     | `busy` or `idle`                                                                                                                      |
| `kind`       | `interactive` or `background`                                                                                                         |
| `entrypoint` | `cli`, `ide`, or other launch method                                                                                                  |
| `version`    | Claude Code version string                                                                                                            |
| `updatedAt`  | Tracks status transitions (busy/idle), **not** continuous activity; a session actively working can show `updatedAt` 30+ minutes stale |

### IDE lock files

Separate from session files, IDE connections register lock files at `~/.claude/ide/<port>.lock`:

```json
{
  "pid": 5245,
  "workspaceFolders": ["/Users/me/some-project"],
  "ideName": "Visual Studio Code",
  "transport": "ws",
  "runningInWindows": false,
  "authToken": "..."
}
```

Multiple lock files can point to the same PID (one VS Code process with multiple workspace windows). These survive
across sessions; a lock file existing means the IDE connection is open, not that a Claude session is active within it.

### Daemon roster

The background daemon tracks its own state at `~/.claude/daemon/roster.json`:

```json
{
  "proto": 1,
  "supervisorPid": 20260,
  "updatedAt": 1782996562538,
  "workers": {}
}
```

## Self-identification

A session can identify its own registry entry through the process tree. Bash commands within a session run as children
of the `claude` process, so `$PPID` (or the parent's parent, depending on shell nesting) maps to a `<pid>.json` file
in the registry.

The environment also exposes:

- `CLAUDE_CODE_ENTRYPOINT`: `cli` or `ide`.
- `AI_AGENT`: `claude-code_<version>_agent`.
- `CLAUDE_CODE_EFFORT_LEVEL`: the session's effort level.

The session ID itself is **not** directly exposed as an environment variable, but is discoverable by reading the
registry file matching the parent PID.

## Stale entry detection

Sessions that crash or are killed without cleanup leave orphan files. Check liveness with `ps -p <pid>`:

```sh
for f in ~/.claude/sessions/*.json; do
  pid=$(python3 -c "import json; print(json.load(open('$f'))['pid'])")
  alive=$(ps -p "$pid" -o command= 2>/dev/null && echo "ALIVE" || echo "STALE")
  cwd=$(python3 -c "import json; print(json.load(open('$f'))['cwd'])")
  echo "$alive pid=$pid cwd=$cwd"
done
```

## Practical value

From the registry alone, a session can determine:

- How many sibling sessions are active right now.
- Which projects they are working in.
- Whether any of them share the same project.
- Whether they are interactive or background.
- How long they have been running.

It **cannot** determine:

- What a sibling session is currently doing (no task or prompt visibility).
- Whether it has modified specific files (use `git status` or file timestamps instead).
- Its conversation history or context.

The registry's primary use is as the **discovery** complement to
[cross-session live propagation][Propagating knowledge between concurrent sessions].
A session discovers siblings via the registry, then uses the file-watching mechanism on
shared auto-loaded files (see [Propagating knowledge between concurrent sessions]) to communicate with them.

| Signal       | Location                        | Scope                                             |
| ------------ | ------------------------------- | ------------------------------------------------- |
| Sessions     | `~/.claude/sessions/*.json`     | Active sessions (with stale detection)            |
| IDE locks    | `~/.claude/ide/*.lock`          | Open IDE connections (not 1:1 with sessions)      |
| Daemon       | `~/.claude/daemon/roster.json`  | Background daemon state                           |
| Session env  | `~/.claude/session-env/<uuid>/` | Per-session directories (historical; often empty) |
| Session logs | `~/.claude/session-logs/`       | Daily logs of session activity                    |
| Tasks        | `~/.claude/tasks/<uuid>/`       | Per-session task state                            |

Verified against Claude Code v2.1.193 (2026-07-06).

## Further readings

- [Personal experiments]
- [Propagating knowledge between concurrent sessions]
- [Claude Code]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->

<!-- Knowledge base -->
[Claude Code]: ../claude%20code.md
[Personal experiments]: README.md
[Propagating knowledge between concurrent sessions]: cross-session%20live%20propagation.md
