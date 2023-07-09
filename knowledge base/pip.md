# PIP

Package installer for Python.

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Further readings](#further-readings)

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Install packages.
pip install 'yamllint'
pip install --user 'ansible'

# Upgrade packages.
pip install -U 'pip'

# Upgrade the included `pip` executable on Mac OS X.
~/Library/Python/3.8/bin/pip3 install --user --upgrade 'pip'

# Upgrade all currently installed packages.
pip install --requirement <(pip freeze | sed 's/==/>=/') --upgrade

# Generate a list of the outdated packages.
pip list --outdated

# Remove orphaned dependencies.
# Requires `pip-autoremove`.
pip-autoremove
```

## Configuration

INI format files, on those levels:

Level | Scope | File locations
---|---|---
global | System-wide, shared | The `pip` subdirectory in any of the directories defined in `XDG_CONFIG_DIRS` if it exists (i.e. `/etc/xdg/pip/pip.conf`)<br/>`/etc/pip.conf`
user | Per-user | `$HOME/.config/pip/pip.conf`<br/>`$HOME/.pip/pip.conf` (legacy)
site | Per-environment | `$VIRTUAL_ENV/pip.conf`
shell | Active shell session | Value of `PIP_CONFIG_FILE`

When multiple configuration exist, pip **merges** them in the following order:

1. shell
1. global
1. user
1. site

Latter files override values from previous files, i.e. the global timeout specified in the global file will be superseded by the one defined in the user file.

## Further readings

- [Configuration]

<!--
  References
  -->

<!-- Upstream -->
[configuration]: https://pip.pypa.io/en/stable/topics/configuration/
