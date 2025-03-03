# Task

Task runner aiming to be simpler and easier to use than [GNU Make].

1. [TL;DR](#tldr)
1. [Usage](#usage)
1. [Variables](#variables)
1. [Call other tasks](#call-other-tasks)
   1. [Call root tasks from non-flattened included files](#call-root-tasks-from-non-flattened-included-files)
1. [Troubleshooting](#troubleshooting)
   1. [Dry run does not print the commands that would be executed](#dry-run-does-not-print-the-commands-that-would-be-executed)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Taskfiles are Task's Makefile counterpart.<br/>
Taskfiles are written in YAML.

Task leverages `mvdan.cc/sh` to run commands, which is a native Go shell interpreter.<br/>
It allows to write `sh`/`bash` commands and have them work even where `sh` or `bash` are usually not available (e.g.:
Windows) as long as any called executable is available in `PATH`.

Pros:

- Taskfiles are more readable than Makefiles.
  Specifically:

  - No need to use tabs.
  - No need for special symbols.
  - Easier environment variables management.

Cons:

- Taskfiles are written in YAML. ≈(・ཀ・≈)<br/>
  That makes them very much similar to \[[Gitlab] / [Azure Devops]]'s pipelines, and if one has any experience with them
  one knows what a pain that can be.

Uses Go's [text/template] package to interpolate values.

Environment variables (`env: {}, dotenv: []`) are available in the shell used by commands.<br/>
Variables (`vars: {}`) are **only** available to Task while executing templates, but **will default to environment
variables** with the same name.

<details>
  <summary>Setup</summary>

```sh
# Install the executable.
brew install 'go-task'
choco install 'go-task'
dnf install 'go-task'
go install 'github.com/go-task/task/v3/cmd/task@latest'
snap install 'task' --classic
zypper install 'https://github.com/go-task/task/releases/download/v3.39.2/task_linux_amd64.rpm'

# Setup the shell's completion.
task --completion 'fish' > ~/'.config/fish/completions/task.fish'
task --completion 'zsh'  > '/usr/local/share/zsh/site-functions/_task'
task --completion 'bash' > '/etc/bash_completion.d/task'

# Create a new 'Taskfile.yml' file in the current folder.
task --init
```

</details>
<details>
  <summary>Usage</summary>

```sh
# Run tasks.
# No tasks given --> assumed one named 'default'
task
task 'assets'
task -v 'build:python' 'deploy:app'

# Simulate running tasks.
task -n 'bootstrap'
task --dry --verbose 'lint' 'validate:ansible'
```

</details>

## Usage

1. Create a file called `Taskfile.yml`, `taskfile.yml`, `Taskfile.yaml`, `taskfile.yaml`, `Taskfile.dist.yml`,
   `taskfile.dist.yml`, `Taskfile.dist.yaml`, or `taskfile.dist.yaml` (ordered by priority) in the root of one's
   project.

1. Run tasks by their name:

   ```sh
   task 'assets' 'build:python'
   task --dry 'bootstrap'
   ```

   If task names are omitted, a task named `default` will be assumed.

## Variables

Set **environment** variables at global or task level with `env: {}`.<br/>
They are made available in the shell used by commands.

<details style="padding: 0 0 1em 1em;">

```yml
env:
  SOME_VAR: some DEFAULT value
tasks:
  env_vars:test:
    env:
      SOME_VAR: some value
    cmds:
      - echo $SOME_VAR
```

</details>

**Exported** and **command-specific** shell variables **take precedence** over the ones defined in the Taskfile.

<details style="padding: 0 0 1em 1em;">

```sh
$ task env_vars:test
some value

$ set SOME_VAR 'some OTHER value'
$ task env_vars:test
some value

$ set -x SOME_VAR 'some OTHER value'
$ task env_vars:test
some OTHER value

$ SOME_VAR='some EPHEMERAL value' task env_vars:test
some EPHEMERAL value
```

</details>

Task accepts setting environment variables **inside** the command itself like `make` due to some shells not supporting
the usual syntax.

<details style="padding: 0 0 1em 1em;">

```sh
# These are equivalent
CONTENT='Hello, World!' FILE=file.txt MESSAGE="All done!" task write-file print
task write-file FILE=file.txt "CONTENT=Hello, World!" print "MESSAGE=All done!"
```

</details>

Include **environment** variables from `.env`-like files at global or task level with `dotenv: []`.<br/>
Non-existing files are **ignored** in a similar manner to `make`'s `-include` directive (with the prefixed dash).

<details style="padding: 0 0 1em 1em;">

```yml
dotenv:
  - .env
  - .env.local
tasks:
  env_vars:test:
    dotenv:
      - .env.task
      - .env.task.local
```

</details>

Environment variables set in `env: {}` **take precedence** over the ones loaded from `dotenv` **at the same level**.

```mermaid
graph LR
  gd["`dotenv: []`"] --- ge["`env: {}`"]
  ge["`env: {}`"] --- td["`task.dotenv: []`"]
  td["`task.dotenv: []`"] --- te["`task.env: {}`"]
  te["`task.env: {}`"] --- se["`shell.export`"]
  se["`shell.export`"] --- ce["`command.env`"]
```

<br/>

Variables (`vars: {}`) are **only** available to Task while executing templates, but **will default to environment
variables** with the same name.

Task execution looks for variables in the following order (first-come-first-served):

- Variables declared in the task's definition.
- Variables provided when calling a task from another.
- Variables defined in included Taskfiles.
- Variables provided when including Taskfiles.
- Global variables.
- Environment variables.

```mermaid
graph LR
  ev["`environment variables`"] --- gv["`vars: {}`"]
  gv["`vars: {}`"] --- iv["`includes[].vars: {}`"]
  iv["`includes[].vars: {}`"] --- it["`includes[]`"]
  it["`includes[]`"] --- tc["`task.cmd.'task'`"]
  tc["`task.cmd.'task'`"] --- te["`task.env`"]
```

## Call other tasks

Use `task:` followed by the call**ed** task name as the command in the call**ing** task.

```yml
tasks:
  task:being:called: { … }
  task:calling:
    cmd: task: task:being:called
```

### Call root tasks from non-flattened included files

Refer an empty namespace by prepending the name of the task with `:`.

```yml
# $ROOT/Taskfile.yml
includes:
  subproject:
    taskfile: subproject
    dir: subproject
tasks:
  task:of:interest: { … }
```

```yml
# $ROOT/subproject/Taskfile.yml
tasks:
  some:task:
    cmd:
      task: :task:of:interest
```

## Troubleshooting

### Dry run does not print the commands that would be executed

<details>
  <summary>Root cause</summary>

Command simulations do **not** print commands to output when setting `silent: true` at any level.

</details>

<details>
  <summary>Solution</summary>

Force the print using `-v, --verbose` when `silent` is set to `true`, or set it to `false` at task level.

</details>

## Further readings

- [Website]
- [Github]
- [Demystification of taskfile variables]

### Sources

- [Usage]
- [Stop Using Makefile (Use Taskfile Instead)]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[azure devops]: cloud%20computing/azure/devops.md
[gitlab]: gitlab/README.md
[gnu make]: gnu%20userland/make.md

<!-- Files -->
<!-- Upstream -->
[github]: https://github.com/go-task/task
[usage]: https://taskfile.dev/usage/
[website]: https://taskfile.dev/

<!-- Others -->
[demystification of taskfile variables]: https://medium.com/@TianchenW/demystification-of-taskfile-variables-29b751950393
[stop using makefile (use taskfile instead)]: https://dev.to/calvinmclean/stop-using-makefile-use-taskfile-instead-4hm9
[text/template]: https://pkg.go.dev/text/template
