# YADM

Yet Another Dotfile Manager.

## TL;DR

```sh
# Create a new repository.
yadm init \
 && yadm add .gitconfig \
 && yadm commit \
 && yadm remote add origin git@gitlab.com:user/dotfiles.git \
 && yadm push -u origin main

# Restore an existing remote repository.
yadm clone git@gitlab.com:user/dotfiles.git \
 && yadm reset --hard HEAD \
 && yadm status

# Set git config values.
yadm gitconfig user.email username@email.coom
yadm gitconfig user.name 'User Name'

# Set a local class on the host.
yadm config local.class 'Work'
```

## Class and overrides

_Class_ is a special value stored **locally** on each host (inside the local repository). To use alternate symlinks using `##class.<CLASS>`, one must set the value of _Class_ in the `local.class` setting:

```sh
yadm config local.class Work
```

Similarly, the values of _OS_, _Hostname_, and _User_ can be manually overridden using the configuration options `local.os`, `local.hostname`, and `local.user` respectively.

## Alternate files

Check the official docs on [alternate files] for the updated information.

`yadm` will automatically create a symbolic link to the appropriate version of a file when its filename is appended a valid suffix. The suffix contains the conditions that must be met for that file to be used, and is `##` followed by any number of conditions separated by commas, like `.zshrc##<condition>[,<condition>,…]`.

Each condition is an attribute/value pair separated by a period, like `os.Darwin`. Some conditions do not require a value, and in that case the period and value can be omitted. Most attributes can be abbreviated as a single letter.

Attribute        | Description
-----------------|------------
`template`, `t`  | Valid when the value matches a supported template processor. See the [Templates](#templates) section for more details
`user`, `u`      | Valid if the value matches the current user. The current user is calculated by running `id ‑u ‑n` on the host
`distro`, `d`    | Valid if the value matches the distro. The distro is calculated by running `lsb_release ‑si`; if `lsb_release` is not available, the value will be **the ID** specified in the `/etc/os-release` file
`os`, `o`        | Valid if the value matches the OS. The OS is calculated by running `uname ‑s` on Unix systems; the OS for Windows Subsystem for Linux is reported as _WSL_ even though uname identifies as "Linux", and the OS for Linux-like runtimes for Windows (e.g. MinGW, Cygwin) is obtained by running `uname -o`
`class`, `c`     | Valid if the value matches the `local.class` configuration. The Class must be manually set using `yadm config local.class <class>`
`hostname`, `h`  | Valid if the value matches the **short** hostname. The hostname is calculated by running `uname ‑n` and trimming off any domain
`default`        | Valid when no other alternate is valid
`extension`, `e` | A special condition that doesn't affect the selection process; its purpose is instead to allow the alternate file to end with a certain extension to e.g. make editors highlight the content properly

One may use any number of conditions, in any order. An alternate file will only be used if **ALL** conditions are met. For all files:

- managed by `yadm`'s repository, or
- listed in `$HOME/.config/yadm/encrypt`

symbolic links will be created for the most appropriate version if they match this naming convention.

The _most appropriate_ version of a file is determined by calculating a score for each version of it:

- a template **is always scored higher than any symlink condition**
- files with more conditions **will always be favored**
- any invalid condition will disqualify that file completely

If one doesn't care to have all versions of alternates stored in the same directory as the generated symlink, one can place them in the `$HOME/.config/yadm/alt` directory. The generated symlink or processed template will be created using the same relative path.

If no `##default` version exists and no files have valid conditions, no link will be created.

Links are also created for directories named this way, as long as they have at least one `yadm` managed file within them.

`yadm` will automatically create the links by default. This behaviour can be disabled using the `yadm.auto-alt` setting. Even if disabled, links can be manually created by running `yadm alt`:

```sh
# force (re)creation of links based on alternate files
yadm alt
```

## Templates

Check the official docs on [templates] for the updated information.

## Further readings

- the project's [homepage]
- [Alternate files]
- [Templates]

[homepage]: https://yadm.io/

[alternate files]: https://yadm.io/docs/alternates
[templates]: https://yadm.io/docs/templates
