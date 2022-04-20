# ASDF

`asdf` is a CLI tool to manage multiple language runtime versions on a per-project basis. It works like `gvm`, `nvm`, `rbenv` and `pyenv` (and more) all in one.

## TL;DR

```shell
# list installed plugins
asdf plugin list

# list available plugins
asdf plugin list all

# install plugins
asdf plugin add helm

# update plugins
asdf plugin update kubectl
asdf plugin update --all

# remove plugins
asdf plugin remove terraform

# list installed versions
asdf list elixir

# list available versions
asdf list all elixir

# install a version
asdf install erlang latest
asdf install terraform 1.1.1

# set a specific installed version to use
asdf global helm 3.3 3.2
asdf shell erlang latest
asdf local elixir system

# uninstall a version
asdf uninstall helm 3.3

# show the current status
asdf current
asdf current helm
```

## Installation

```shell
# install the program
brew install asdf

# load its shell file and completion
# or just load oh-my-zsh's plugin
. $(brew --prefix asdf)/asdf.sh
```

## Plugins management

```shell
# list installed plugins
asdf plugin list
asdf plugin list --urls

# list all plugins (available too)
asdf plugin list all

# asdf plugin add $PLUGIN_NAME [$PLUGIN_URL]
asdf plugin add helm

asdf plugin update --all
asdf plugin update $PLUGIN_NAME

asdf plugin remove $PLUGIN_NAME
```

### Plugins gotchas

`asdf plugin list all` or `asdf plugin add $PLUGIN_NAME` also trigger a sync to the plugins repository.

## Versions management

```shell
# list installed versions for a plugin
# asdf list $PLUGIN_NAME
asdf list elixir

# list all available versions for a plugin
# asdf list all $PLUGIN_NAME
asdf list all elixir

# install a plugin version
# asdf install $PLUGIN_NAME $PLUGIN_VERSION
asdf install erlang latest

# check current plugin version
# asdf current [$PLUGIN_NAME]
asdf current
asdf current helm

# set plugin version
# asdf global|shell|local $PLUGIN_NAME $PLUGIN_VERSION [$PLUGIN_VERSION,...]
asdf global helm 3.3 3.2
asdf shell erlang latest
asdf local elixir latest

# fallback to system version
# asdf local $PLUGIN_NAME system
asdf local python system

# uninstall a version
# asdf uninstall $PLUGIN_NAME $PLUGIN_VERSION
asdf uninstall helm 3.3
```

## Further readings

- the project's [homepage]
- the project's [github] page
- [plugins list]

[github]: https://github.com/asdf-vm/asdf
[homepage]: https://asdf-vm.com/
[plugins list]: https://github.com/asdf-vm/asdf-plugins
