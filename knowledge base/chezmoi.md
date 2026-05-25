# Chezmoi

Multi-machine dotfiles manager written in Go.

1. [TL;DR](#tldr)
1. [Save the current state to a remote repository](#save-the-current-state-to-a-remote-repository)
1. [Gotchas](#gotchas)
1. [Snippets](#snippets)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

The source directory is always exposed as `$.chezmoi.sourceDir`.

Templating uses the [Go text/template] library and [Sprig].

<details>
  <summary>Setup</summary>

```sh
# Install.
brew install 'chezmoi'
sudo zypper install 'chezmoi'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Initialize.
chezmoi init
chezmoi init 'https://github.com/username/dotfiles.git' --branch 'chezmoi'

# Initialize, checkout and apply all at once.
chezmoi init --apply --verbose https://github.com/username/dotfiles.git

# Add existing files to the managed set.
chezmoi add '.gitconfig'
chezmoi add --follow --template '.vimrc'  # follow symlinks, add as template
chezmoi add --encrypt '.ssh/id_ed25519'   # add encrypted

# Edit files.
# The given files need to have been added first.
chezmoi edit '.tmux.conf'

# List files with changes.
chezmoi status

# Check what files would change during an apply.
chezmoi apply --dry-run --verbose
chezmoi apply -nv

# Check what content would change.
chezmoi diff

# Apply changes.
chezmoi apply

# List the files managed by chezmoi.
chezmoi managed
chezmoi list

# Show the full list of variables.
# Includes custom data from the configuration file.
chezmoi data

# Test templates.
chezmoi execute-template < .local/share/chezmoi/dot_gitconfig.tmpl
chezmoi execute-template --init --promptString email=me@home.org < ~/.local/share/chezmoi/.chezmoi.yaml.tmpl

# Use `git` on chezmoi's data storage.
chezmoi git add -- '.'
chezmoi git commit -- -m "commit message"
chezmoi git pull -- --rebase
chezmoi git push -- --set-upstream 'origin' 'main'

# Fetch the latest changes from a remote repository.
chezmoi update
```

</details>

## Save the current state to a remote repository

```sh
$ chezmoi cd
chezmoi $> git remote add 'origin' 'https://github.com/username/dotfiles.git'
chezmoi $> git push -u 'origin' 'main'
chezmoi $> exit
$
```

## Gotchas

- [Sprig]'s `toPrettyJson` sorts keys **alphabetically**. This is caused by Go's `json.MarshalIndent`, and the library
  does **not** make its behaviour configurable.

  Tools (e.g. Claude Code) might edit a live file with a different key order, which causes `chezmoi diff` to report
  pure-reorder noise. A workaround it to set the chezmoi's `diff.command` to a tool that manages this, like `jd` and
  `dyff`, or a wrapper that normalises both sides via `jq -S '.'`

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example: wrapper</summary>

  When both files are valid JSON, fall back to `git diff --no-index` for non-JSON:

  ```bash
  #!/usr/bin/env bash

  set -u

  destination=$1       # live file in $HOME
  rendered_target=$2   # chezmoi's rendered target

  if jq empty "$destination" 2>/dev/null && jq empty "$rendered_target" 2>/dev/null
  then
    work_dir=$(mktemp -d) && trap 'rm -rf "$work_dir"' EXIT
    jq -S '.' "$destination"      > "$work_dir/live.json"
    jq -S '.' "$rendered_target"  > "$work_dir/target.json"
    git --no-pager diff --no-index --no-ext-diff \
      "$work_dir/live.json" "$work_dir/target.json"
  else
    git --no-pager diff --no-index --no-ext-diff "$destination" "$rendered_target"
  fi
  ```

  `git diff --no-index <(…) <(…)` yields unreadable `/dev/fd/63`-style labels in the diff header. Using named temporary
  files instead of process substitution solves this.

  </details>

  Wire any of them in `.chezmoi.yaml.tmpl`:

  ```gotmpl
  {{-
      $_ := set $defaults "diff" (dict
                "command" (joinPath $.chezmoi.homeDir ".local/bin/chezmoi-diff")
                "args"    (list `{{ .Destination }}` `{{ .Target }}`)
            )
  }}
  ```

  After editing the template, regenerate it via `chezmoi init` (`apply` does **not** update the live configuration file
  at `~/.config/chezmoi/chezmoi.yaml`).

- ~~Due to a feature of a library used by chezmoi, all custom variable names in the configuration file are converted to
  lowercase; see the [custom data fields appear as all lowercase strings] GitHub issue for more information.~~

  ```toml
  # configuration file
  [data]
    AwesomeCustomField = "my Awesome custom Value"
    normallookingcustomfield = "normalLookingValue"
  ```

  ```txt
  map[awesomecustomfield:my Awesome custom Value chezmoi:… normallookingcustomfield:normalLookingValue]
  ```

  > Solved in [2376](https://github.com/twpayne/chezmoi/pull/2376/files).

- Chezmoi's `glob` function only accepts **absolute** paths. Relative ones **silently** return an empty list
  (`[]`).<br/>
  `glob` only returns existing files.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example: canonical pattern for templating</summary>

  There is **no** `$.chezmoi.templatesDir` variable. The templates' directory is always `.chezmoitemplates/` under
  `$.chezmoi.sourceDir`.

  ```gotemplate
  {{- range $f := glob (joinPath $.chezmoi.sourceDir ".chezmoitemplates" "*.profile") }}
  {{-   includeTemplate (base $f) $ }}
  {{- end }}
  ```

  `base $f` strips the directory prefix from the absolute path returned by `glob` before passing the name to
  `includeTemplate` (which expects a path _relative_ to `.chezmoitemplates`).

  </details>

- Chezmoi reads files from its source directory on the filesystem, not from git history. A file that is `.gitignore`d
  still exists in the source directory, and is fully visible to `chezmoi apply`. This makes it referenceable by `stat`,
  `include`, `includeTemplate`, and copied by `run_` scripts.

  Gitignored source files do **not** survive a fresh `chezmoi init` that clones the repository on a new machine and
  they only exist locally. This makes it an optimal design for machine-local secrets/config that shouldn't replicate:

  ```gitignore
  # All host-specific files are local-only
  .hosts/
  ```

  ```gotemplate
  {{- if stat (joinPath $.chezmoi.sourceDir $hostFile) }}
  {{   includeTemplate $hostFile . }}
  {{- end }}
  ```

- In a `range` loop, Go templates rebind `.` to the **current** iteration value. Inside a `range`, `includeTemplate`
  calls must pass `$` (the root context), **not** `.`:

  ```gotemplate
  {{- range $f := glob (joinPath $.chezmoi.sourceDir ".chezmoitemplates" "*.profile") }}
  {{   includeTemplate (base $f) $ }}   {{/* ✓ pass $, not . */}}
  {{- end }}
  ```

  Passing `.` makes the included template receive the loop value (a file path string) instead of the chezmoi data
  tree. Subsequent `.chezmoi.os` (or similar) access fails with `can't evaluate field chezmoi in type string`. `$` is
  unaffected by `range` and always refers to the root context.

- `mustMergeOverwrite` (and `mergeOverwrite`) perform a deep merge on maps, but **replace** arrays entirely. Host
  overrides containing arrays at the same path as the base template **silently drop** the base's array entries.

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Example</summary>

  ```gotemplate
  {{- $base := includeTemplate "app/settings.json" . | fromJson }}
  {{- $override := includeTemplate $hostFile $ | fromJson }}
  {{- $_ := mustMergeOverwrite $base $override }}
  ```

  If both define a `permissions.allow` array, the override's array **completely replaces** the base's. Rules added only
  to the base template **silently** disappear in the merged output for hosts that have their own override.

  </details>

  Fix this by duplicating shared array entries in every override that redefines that array, or restructure it to avoid
  arrays in overrides. Chezmoi's Go template functions do **not** currently have built-in array-merge strategy.

## Snippets

```go
{{- /* Overwrite settings from the host-specific configuration files, if existing. */}}

{{- $hostConfigFiles := list
        (print ".chezmoi_" .chezmoi.hostname ".yaml") }}
{{- range $f := $hostConfigFiles }}
{{-   if stat (joinPath $.chezmoi.sourceDir $f) }}
{{-     $hostConfig := dict }}
{{-     $hostConfig = include $f | fromYaml }}
{{-     $config = mergeOverwrite $config $hostConfig }}
{{-   end }}
{{- end }}

{{- $hostEncryptedConfigFiles := list
        (print "encrypted_chezmoi_" .chezmoi.hostname ".yaml" (dig "age" "suffix" ".age" .))
        (print "encrypted_chezmoi_" .chezmoi.hostname ".yaml" (dig "gpg" "suffix" ".asc" .)) }}
{{- /* A value for .encryption *must* be set *before execution* to be able to decrypt values. */}}
{{- /* Ignore this step if .encryption is not set. */}}
{{- if hasKey . "encryption" }}
{{-   range $f := $hostEncryptedConfigFiles }}
{{-     if stat (joinPath $.chezmoi.sourceDir $f) }}
{{-       $hostConfig := dict }}
{{-       $hostConfig = include $f | decrypt | fromYaml }}
{{-       $config = mergeOverwrite $config $hostConfig }}
{{-     end }}
{{-   end }}
{{- end }}
```

## Further readings

- Chezmoi [user guide]
- [Go text/template]
- [Sprig]

### Sources

- [Source state attributes]
- [cheat.sh]
- [Custom data fields appear as all lowercase strings]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Upstream -->
[user guide]: https://www.chezmoi.io/user-guide/setup/
[source state attributes]: https://www.chezmoi.io/reference/source-state-attributes/

<!-- Others -->
[cheat.sh]: https://cheat.sh/chezmoi
[custom data fields appear as all lowercase strings]: https://github.com/twpayne/chezmoi/issues/463
[go text/template]: https://pkg.go.dev/text/template
[sprig]: https://masterminds.github.io/sprig/
