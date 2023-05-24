# Macports

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Installation](#installation)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

Default ports install location is `/opt/local`.

```sh
# Get help on commands.
port help 'install'
port help 'select'

# Search for ports.
port search 'completion'
port search --name 'parallel'

# Get info on specific ports.
port info 'zsh-completions'

# Get ports' variants.
port variants 'k9s'

# Install ports.
sudo port install 'zsh-completions' 'apple-completion'
sudo port install 'nmap' -subversion                   # uses a variant
sudo port install -d 'gettext'                         # debug mode

# List all installed ports.
port installed
port echo installed

# List all ports that have been explicitly installed by the user.
port echo requested

# List all available ports.
port list

# List all versions of specific ports only.
port list 'nmap'

# list all files installed by ports.
# The port must be already installed for this to work.
port contents 'py38-netaddr'

# List ports providing a specific file.
# The port must be already installed for this to work.
port provides '/opt/local/bin/envsubst'

# Remove ports.
sudo port uninstall 'parallel'
sudo port uninstall --follow-dependencies 'fzf'

# List available choices for groups of packages.
port select --list 'python'

# Show the current port selection.
port select --summary

# Set a default version.
# Symlinks the "executable"'s version to 'opt/local/bin/executable'.
sudo port select --set postgresql postgresql12
sudo port select --set python3 python310
sudo port select --set virtualenv virtualenv310

# Update `macports` itself to the latest version.
# Also syncs the latest ports definitions.
sudo port selfupdate

# Deactivate active ports.
sudo port deactivate 'stow'

# Activate inactive ports.
sudo port activate 'stow'

# List all outdated ports.
port echo outdated

# Upgrade ports.
sudo port upgrade 'tree'

# Upgrade all outdated ports.
sudo port upgrade outdated

# Clean out all temporary assets of ports.
sudo port clean -f --all 'parallel'

# Clean up leftovers.
sudo port reclaim

# List all inactive ports.
# Ports are deactivated when a newer version gets installed.
port echo inactive

# Remove all inactive ports.
sudo port uninstall inactive

# List ports' dependencies.
port deps 'chezmoi'

# Recursively list all ports depending on given ports.
port rdeps 'pcre'

# List the installed ports depending on given ports.
port dependents 'bzip2'

# Recursively list all the installed ports that depend on given ports.
port rdependents 'libedit'

# View ports' notes if any are available.
# Notes are displayed right after a port is installed.
# The port must be already installed for this to work.
port notes 'postgres12'

# Get the location of ports within the ports tree.
port dir 'zlib'

# Get the location of the tarball of ports.
# The port must be already installed for this to work.
port location 'readline'

# Get the location of ports' portfiles.
port file 'openssl11'

# Get the location of the working directory for ports, if it exists.
port work 'popt'
```

## Installation

See the [website] for the installation instructions.

## Further readings

- [Website]
- Official user [guide]
- Public [ports] database
- [Mac OS X]

## Sources

All the references in the [further readings] section, plus the following:

- [cheat.sh]

<!-- project's references -->
[guide]: https://guide.macports.org/
[ports]: https://ports.macports.org/
[website]: https://www.macports.org/

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
[mac os x]: README.md

<!-- external references -->
[cheat.sh]: https://cheat.sh/port
