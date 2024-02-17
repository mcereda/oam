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
# List installed plugins.
asdf plugin list

# List available plugins.
asdf plugin list all

# Add plugins.
asdf plugin add 'helm'

# Update plugins.
asdf plugin update 'kubectl'
asdf plugin update --all

# Remove plugins.
asdf plugin remove 'terraform'

# List installed versions.
asdf list 'elixir'

# List available versions.
asdf list all 'elixir'

# Install versions.
asdf install 'erlang' 'latest'
asdf install 'terraform' '1.1.1'

# Install all versions specified in '.tool-versions'.
asdf install

# Set specific installed versions for use.
asdf global 'helm' '3.3' '3.2'
asdf shell 'erlang' 'latest'
asdf local 'elixir' 'system'

# Uninstall versions.
asdf uninstall 'helm' '3.3'

# Show the current status.
asdf current
asdf current 'helm'
```

## Installation

```sh
# Install the application.
brew install 'asdf'

# Load ASDF's environment and completion.
# Alternatively, just load oh-my-zsh's plugin for it.
. "$(brew --prefix 'asdf')/asdf.sh"
echo -e "source "(brew --prefix asdf)"/libexec/asdf.fish" | tee ~/'.config/fish/conf.d/asdf.fish'
```

## Plugins management

```sh
# List installed plugins.
asdf plugin list
asdf plugin list --urls

# List all available and plugins.
asdf plugin list all

# Add plugins.
asdf plugin add 'helm'

# Update plugins.
asdf plugin update --all
asdf plugin update 'erlang'

# Remove plugins.
asdf plugin remove 'terraform'
```

### Plugins gotchas

`asdf plugin list all` or `asdf plugin add $PLUGIN_NAME` also trigger a sync with the plugins repository.

## Versions management

```sh
# List installed versions.
asdf list 'elixir'

# List all available versions of a plugin.
asdf list all 'elixir'

# Install a version.
asdf install 'erlang' 'latest'

# Check currently installed and configured versions.
asdf current
asdf current 'helm'

# Configure versions for use.
asdf global 'helm' '3.3' '3.2'
asdf shell erlang 'latest'
asdf local elixir 'latest'

# Fallback to the system-installed version.
asdf local python 'system'

# Uninstall versions.
asdf uninstall 'helm' '3.3'
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

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/asdf-vm/asdf
[homepage]: https://asdf-vm.com/
[plugins list]: https://github.com/asdf-vm/asdf-plugins

<!-- Files -->
[.tool-versions example]: ../examples/dotfiles/.tool-versions
