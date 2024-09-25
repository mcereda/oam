# PIP

Package installer for Python.

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Further readings](#further-readings)

## TL;DR

Stores the cache in:

- `$XDG_CACHE_HOME` (default: `~/.cache/pip`) on Linux.
- `~/Library/Caches/pip` on Mac OS X.
- `%LocalAppData%\pip\Cache` on Windows.

pip will also respect XDG_CACHE_HOME.

Creates **temporary** files to unpack/build/doOtherStuff to packages, then deletes them after installation.<br/>
It checks, in order, if any of the directories used by `tempfile.gettempdir()` **exists**, and is **readable** and
**writable**; the first one matching all the requirements is used.<br/>
The directory priority at the time of writing is as follows:

1. `$TMPDIR`
1. `$TEMP`
1. `$TMP`
1. `C:\TEMP`, `C:\TMP`, `\TEMP`, and `\TMP` on Windows; `/tmp`, `/var/tmp`, and `/usr/tmp` on any other platform.
1. The current working directory

```sh
# Install packages.
pip install 'yamllint'
pip install --user 'ansible==10.1.0'
pip install -U --require-virtualenv -r 'requirements.txt' --no-cache-dir

# Upgrade packages.
pip install -U 'pip'

# Upgrade the included `pip` executable on Mac OS X.
~/Library/Python/3.8/bin/pip3 install --user --upgrade 'pip'

# Upgrade all currently installed packages.
pip install --requirement <(pip freeze | sed 's/==/>=/') --upgrade

# Generate a list of the outdated packages.
pip list --outdated

# Get the currently configured cache directory.
pip cache dir

# Provide an overview of the contents of the cache.
pip cache info

# List files from the 'wheel' cache.
pip cache list
pip cache list 'ansible'

# Removes files from the 'wheel' cache.
# Files from the 'HTTP' cache are left untouched at this time.
pip cache remove 'setuptools'

# Clear all files from the 'wheel' and 'HTTP' caches.
pip cache purge

# Remove orphaned dependencies.
# Requires `pip-autoremove`.
pip-autoremove
```

## Configuration

INI format files, on those levels:

| Level  | Scope                | File locations                                                                                                                                 |
| ------ | -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| global | System-wide, shared  | The `pip` subdirectory in any of the directories defined in `XDG_CONFIG_DIRS`, if it exists (i.e. `/etc/xdg/pip/pip.conf`)<br/>`/etc/pip.conf` |
| user   | Per-user             | `$HOME/.config/pip/pip.conf`<br/>`$HOME/.pip/pip.conf` (legacy)                                                                                |
| site   | Per-environment      | `$VIRTUAL_ENV/pip.conf`                                                                                                                        |
| shell  | Active shell session | Value of `PIP_CONFIG_FILE`                                                                                                                     |

When multiple configuration exist, pip **merges** them in the following order:

1. shell
1. global
1. user
1. site

Latter files override values from previous files, i.e. the global timeout specified in the global file will be
superseded by the one defined in the user file.

## Further readings

- [Configuration]
- [`pipx`][pipx]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[configuration]: https://pip.pypa.io/en/stable/topics/configuration/

<!-- Knowledge base -->
[pipx]: pipx.md
