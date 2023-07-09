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

# search an installed package
pacman --query --search ddc

# list all explicitly installed packages
pacman --query --explicit

# set a package as explicitly (manually) installed
pacman --database --asexplicit dkms
# set a package as installed as dependency (automatically installed)
pacman --database --asdeps autoconf

# install zsh unsupervisioned (useful in scrips)
pacman --noconfirm \
	--sync --needed --noprogressbar --quiet --refresh \
	fzf zsh-completions
# completely remove virtualbox-guest-utils-nox unsupervisioned (useful in scrips)
pacman --noconfirm \
	--remove --nosave --noprogressbar --quiet --recursive --unneeded \
	virtualbox-guest-utils-nox
```

## Further readings

- [Prevent pacman from reinstalling packages that were already installed]

<!--
  References
  -->

<!-- Others -->
[Prevent pacman from reinstalling packages that were already installed]: https://superuser.com/questions/568967/prevent-pacman-from-reinstalling-packages-that-were-already-installed#568983
