# Chezmoi

A multi-machine dotfile manager, written in Go.

## TL;DR

```shell
# initialize chezmoi
chezmoi init
chezmoi init https://github.com/username/dotfiles.git

# initialize, checkout and apply
chezmoi init --apply --verbose https://github.com/username/dotfiles.git

# add a file
chezmoi add .gitconfig
chezmoi add --follow --template .vimrc  # follow symlinks, add as template
chezmoi add --encrypt .ssh/id_ed25519   # add encrypted

# edit a file
# the file needs to be added first
chezmoi edit .tmux.conf

# check what files would change during an apply
chezmoi apply --dry-run --verbose

# check what contents would change
chezmoi diff

# apply changes
chezmoi apply

# show the full list of variables
# includes custom data from the configuration file
chezmoi data

# test a template
chezmoi execute-template < .local/share/chezmoi/dot_gitconfig.tmpl
chezmoi execute-template --init --promptString email=me@home.org < ~/.local/share/chezmoi/.chezmoi.yaml.tmpl

# use git on chezmoi's data storage
chezmoi git add -- .
chezmoi git commit -- --message "commit message"
chezmoi git pull -- --rebase
chezmoi git push -- --set-upstream origin main

# fetch the latest changes from a remote repository
chezmoi update
```

## Save the current data to a remote repository

```shell
$ chezmoi cd
chezmoi $> git remote add origin https://github.com/username/dotfiles.git
chezmoi $> git push -u origin main
chezmoi $> exit
$
```

## Gotchas

- templating uses the [Go text/template] library
- due to a feature of a library used by chezmoi, all custom variable names in the configuration file are converted to lowercase; see the [custom data fields appear as all lowercase strings] GitHub issue for more information.

  ```toml
  # configuration file
  [data]
    AwesomeCustomField = "my Awesome custom Value"
    normallookingcustomfield = "normalLookingValue"
  ```

  ```plaintext
  map[awesomecustomfield:my Awesome custom Value chezmoi:… normallookingcustomfield:normalLookingValue]
  ```

## Snippets

```golang
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

[user guide]: https://www.chezmoi.io/user-guide/setup/

[go text/template]: https://pkg.go.dev/text/template
[sprig]: https://masterminds.github.io/sprig/

## Sources

- [cheat.sh]
- [custom data fields appear as all lowercase strings]

[cheat.sh]: https://cheat.sh/chezmoi
[custom data fields appear as all lowercase strings]: https://github.com/twpayne/chezmoi/issues/463
