# ASDF

CLI tool to manage multiple language runtime versions on a per-project basis. It works like `gvm`, `nvm`, `rbenv` and `pyenv` (and more) all in one.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Installation](#installation)
1. [Plugins management](#plugins-management)
   1. [Plugins gotchas](#plugins-gotchas)
1. [Versions management](#versions-management)
   1. [The `.tool-versions` file](#the-tool-versions-file)
1. [Further readings](#further-readings)

## TL;DR

```sh
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

# install a specific version
asdf install erlang latest
asdf install terraform 1.1.1

# install all versions specified in the '.tool-versions' file
asdf install

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

```sh
# install the program
brew install asdf

# load its shell file and completion
# or just load oh-my-zsh's plugin
. $(brew --prefix asdf)/asdf.sh
```

## Plugins management

```sh
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

```sh
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

### The `.tool-versions` file

Stores the global (`~/.tool-versions`) or local (`./.tool-versions`) settings for ASDF.

```txt
# Multiple versions can be set by separating them with a space.
# plugin_name  default_version  first_fallback_version ... nth_fallback_version
python system 3.11.0 3.10.9 3.9.7
```

The versions listed in such file can be:

- an actual version, like `3.10.9`; plugins that support downloading binaries, will download that versions' binaries
- a git reference, like `ref:v1.0.2-a` or `ref:39cb398vb39`; plugins will download the given tag/commit/branch from github and compile the executable file
- a path, like `path:~/src/elixir`; plugins will reference this path to a (custom, compiled) version of the executable
- the `system` keyword; this causes asdf to passthrough to the version of the tool present on the host system and avoid those which are managed by asdf

## Further readings

- the project's [homepage]
- the project's [github] page
- [plugins list]
- [`.tool-versions` example][.tool-versions example]

<!-- upstream -->
[github]: https://github.com/asdf-vm/asdf
[homepage]: https://asdf-vm.com/
[plugins list]: https://github.com/asdf-vm/asdf-plugins

<!-- in-article references -->
<!-- internal references -->
[.tool-versions example]: ../examples/.tool-versions

<!-- external references -->
