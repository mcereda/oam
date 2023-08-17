# Pipx

Tool to help install and run end-user applications written in Python.

It acts as a package manager using [`pip`][pip] behind the scenes, but is focused on installing and managing Python packages that can be run from the command line directly as applications.

The `install` command automatically creates a Python virtual environment, installs the package, and adds the package's associated applications (entry points) to a location in PATH. For this reason, `pipx` never needs to run as `root`.<br/>
For example, `pipx install 'pycowsay'` makes the `pycowsay` command available globally, but sandboxes the package in its own virtual environment.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Installation.
python3 -m pip install --user 'pipx'
brew install 'pipx'

# Add pipx's binary folders to PATH.
pipx ensurepath
python3 -m pipx ensurepath

# Install applications.
pipx install 'ansible'

# List installed applications.
pipx list

# Run applications *without* installing them globally.
pipx run 'xkcdpass'
pipx run --spec 'package' 'app_with_different_name_in_the_package'
pipx run 'yamllint==1.31.0'

# Upgrade single applications.
pipx upgrade 'pip-autoremove'

# Upgrade all installed applications.
pipx upgrade-all

# Remove installed applications.
pipx uninstall 'azure-cli'
```

## Further readings

- [Website]
- [Pip]

<!--
  References
  -->

<!-- Upstream -->
[website]: https://pypa.github.io/pipx/

<!-- Knowledge base -->
[pip]: pip.md
