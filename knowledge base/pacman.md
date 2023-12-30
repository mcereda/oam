# Pacman

Useful options:

- `--asdeps`
- `--asexplicit`
- `--needed`
- `--unneeded`

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Search installed packages.
pacman -Q -s 'ddc'

# List all explicitly (manually) installed packages.
pacman -Q -e


# Set packages as explicitly (manually) installed.
pacman -D --asexplicit 'dkms'

# Set packages as installed as dependency (automatically installed).
pacman -D --asdeps 'autoconf'


# Refresh repositories' cache.
pacman -Sy


# Download packages from repositories.
# Does *not* install them.
pacman -Sw 'fzf'


# Install packages from repositories.
pacman -S -qy --needed --noprogressbar 'fzf' 'zsh-completions=0.35.0-1'

# Install packages from local directories.
pacman -U 'fzf-0.44.1-1-x86_64.pkg.tar.zst'


# Completely remove packages.
pacman -R -nsu --noprogressbar 'virtualbox-guest-utils-nox'


# Take actions without supervision.
# Useful in scripts.
pacman --noconfirm …
```

## Further readings

- [Prevent pacman from reinstalling packages that were already installed]

<!--
  References
  -->

<!-- Others -->
[Prevent pacman from reinstalling packages that were already installed]: https://superuser.com/questions/568967/prevent-pacman-from-reinstalling-packages-that-were-already-installed#568983
