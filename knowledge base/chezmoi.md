# Chezmoi

Multi-machine dotfiles manager written in Go.

1. [TL;DR](#tldr)
1. [Save the current state to a remote repository](#save-the-current-state-to-a-remote-repository)
1. [Gotchas](#gotchas)
1. [Snippets](#snippets)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Install.
brew install 'chezmoi'
sudo zypper install 'chezmoi'

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

## Save the current state to a remote repository

```sh
$ chezmoi cd
chezmoi $> git remote add 'origin' 'https://github.com/username/dotfiles.git'
chezmoi $> git push -u 'origin' 'main'
chezmoi $> exit
$
```

## Gotchas

- templating uses the [Go text/template] library
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
