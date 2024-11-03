# Task

Task runner aiming to be simpler and easier to use than [GNU Make].

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Taskfiles are Task's Makefile counterpart.<br/>
Taskfiles are written in YAML.

Task leverages `mvdan.cc/sh` to run commands, which is a native Go shell interpreter.<br/>
This allows to write `sh`/`bash` commands and have them work even where `sh` or `bash` are usually not available (e.g.:
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
```

</details>
<details>
  <summary>Usage</summary>

1. Create a file called `Taskfile.yml`, `taskfile.yml`, `Taskfile.yaml`, `taskfile.yaml`, `Taskfile.dist.yml`,
   `taskfile.dist.yml`, `Taskfile.dist.yaml`, or `taskfile.dist.yaml` (ordered by priority) in the root of one's
   project.<br/>
   The `cmds` keys shall contain the commands for their own tasks:

   ```yaml
   version: '3'

   tasks:
     build:
       cmds:
         - go build -v -i main.go

     assets:
       cmds:
         - esbuild --bundle --minify css/index.css > public/bundle.css
   ```

1. Run tasks by their name:

   ```sh
   task 'assets' 'build'
   task --dry 'bootstrap'
   ```

   If task names are omitted, a task named `default` will be assumed.

</details>

## Further readings

- [Website]
- [Github]

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
[stop using makefile (use taskfile instead)]: https://dev.to/calvinmclean/stop-using-makefile-use-taskfile-instead-4hm9
