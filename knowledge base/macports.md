# Macports

See the [website] for the installation instructions.

Default ports install location is `/opt/local`.

## TL;DR

```sh
# get help on a command
port help install
port help select

# search for ports
port search completion
port search --name parallel

# get info on a specific port
port info zsh-completions

# get a port's variants
port variants k9s

# install ports
sudo port install zsh-completions apple-completion
sudo port install nmap -subversion                  # use a variant
sudo port install -d gettext                        # debug mode

# list all installed ports
port installed
port echo installed

# list all ports that have been explicitly installed by the user
port echo requested

# list all available ports
port list
port list nmap   # limit to all versions of a package

# list all files installed by a port
# the port must be installed for this to work
port contents py38-netaddr

# list ports providing a file
# the port must be installed for this to work
port provides /opt/local/bin/envsubst

# remove a port
sudo port uninstall --follow-dependencies fzf

# list available choices for a group
port select --list python

# show the current port selection
port select --summary

# set a default version
sudo port select --set postgresql postgresql12

# update macports itself to the latest version and sync the latest ports definitions
sudo port selfupdate

# deactivate an active port
sudo port deactivate stow
# activate an inactive port
sudo port activate stow

# list all outdated ports
port echo outdated

# upgrade a port
sudo port upgrade tree

# upgrade all outdated ports
sudo port upgrade outdated

# clean out all temporary assets of a port
sudo port clean -f --all parallel

# clean up leftovers
sudo port reclaim

# list all inactive ports
# ports are deactivated when a newer version gets installed
port echo inactive

# remove all inactive ports
sudo port uninstall inactive

# list a port's dependencies
port deps chezmoi

# recursively list all ports depending on the given port
port rdeps pcre

# list the installed ports depending on the given port
port dependents bzip2

# recursively list all the installed ports that depend on this port
port rdependents libedit

# view a port's notes if any are available
# notes are displayed right after a port is installed
# the port must be installed for this to work
port notes postgres12

# get the path of a port within the ports tree
port dir zlib

# get the path of the tarball of a port
# the port must be installed for this to work
port location readline

# get the path to a port's portfile
port file openssl11

# get the path of the working directory for a port if it exists
port work popt
```

## Further readings

- [Website]
- Official user [guide]
- Public [ports] database
- [cheat.sh]

[guide]: https://guide.macports.org/
[ports]: https://ports.macports.org/
[website]: https://www.macports.org/

[cheat.sh]: https://cheat.sh/port
