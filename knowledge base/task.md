# Task

Task runner aiming to be simpler and easier to use than [GNU Make].

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

Pros:

- Taskfiles are more readable than Makefiles.

Cons:

- Taskfiles are written in YAML. ≈(・ཀ・≈)<br/>
  That makes them very much similar to \[[Gitlab] / [Azure Devops]]'s pipelines, and if one has any experience with them
  one knows what a pain that can be.

Taskfiles are Task's Makefile counterpart.<br/>
Taskfiles are written in YAML.

Task uses `mvdan.cc/sh`, a native Go sh interpreter, to run commands.<br/>
This allows to write sh/bash commands and have them work even where `sh` or `bash` are usually not available (e.g.:
Windows) as long as any called executable is available in `PATH`.

<details>
  <summary>Setup</summary>

```sh
# Install the executable.
brew install 'go-task'
choco install 'go-task'
sudo dnf install 'go-task'
sudo snap install 'task' --classic

# Setup the shell's completion.
curl -fsSL 'https://raw.githubusercontent.com/go-task/task/main/completion/fish/task.fish' \
  -o "$HOME/.config/fish/completions/task.fish"
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
   ```

   If task names are omitted, a task named `default` will be assumed.

</details>

## Further readings

- [Website]
- [Github]

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
[website]: https://taskfile.dev/

<!-- Others -->
