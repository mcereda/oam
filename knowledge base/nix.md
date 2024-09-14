# The Nix package manager

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install Nix in single-user mode (suggested).
# Works on most Linux even *without systemd* or with SELinux *enabled*.
# *Not* supported on MacOSX.
bash <(curl -L 'https://nixos.org/nix/install') --no-daemon

# Install Nix in multi-user mode.
# Only works on Linux *using systemd* with SELinux *disabled*. Or MacOSX.
curl -L 'https://nixos.org/nix/install' | sh
bash <(curl -L 'https://nixos.org/nix/install') --daemon


# Uninstall Nix in single-user mode.
# Also remove references from '~/.bash_profile' and '~/.zshenv'.
rm -rf '/nix'

# Uninstall Nix in multi-user mode.
# Oooh boi.
# Check https://nixos.org/manual/nix/stable/installation/uninstall#multi-user.
```

</details>

<details>
  <summary>Usage</summary>

```sh
# List configured channels.
nix-channel --list

# Add channels.
nix-channel --add 'https://channels.nixos.org/nixos-24.05' 'nixos'
nix-channel --add 'https://channels.nixos.org/nixos-24.05-small' 'nixos'
nix-channel --add 'https://channels.nixos.org/nixos-unstable' 'nixos'

# Remove channels.
nix-channel --remove 'nixos'

# Update channels.
nix-channel --update
nix-channel --update 'nixpkgs'


# List installed packages.
nix-env -q
nix-env --query --installed

# List available packages.
# Without '--attr' it takes a worrying amount of resources at the time of
# writing, and froze a VM multiple times during experimentation.
nix-env -qa --attr 'nixpkgs'
nix-env --query --available --attr 'nixpkgs'

# Search packages.
# See <https://nixos.wiki/wiki/Searching_packages>
curl 'https://search.nixos.org/packages?channel=24.05&from=0&size=150&sort=relevance&type=packages&query=vscode'
nix --extra-experimental-features 'nix-command' --extra-experimental-features 'flakes' search 'nixpkgs' 'git'

# Install packages.
nix-env -i 'coreutils'
nix-env --install --attr 'nixpkgs.parallel'

# Update packages.
# After a channel update.
nix-env -u '*'
nix-env --upgrade --attr 'nixpkgs.firefox'

# Remove packages.
nix-env -e 'coreutils'
nix-env --uninstall --dry-run 'parallel'

# Rollback `nix-env` actions.
nix-env --rollback

# Create a new shell environment with specific programs on top of the current
# state of the user environment.
# Useful to test packages without installing them system-wide.
nix-shell -p 'cowsay' 'lolcat'
nix-shell --packages 'cowsay' 'lolcat'

# Create a new shell environment with specific programs on top of the current
# state of the user environment, then run specific commands in it and exit.
nix-shell -p 'cowsay' 'lolcat' --run 'cowsay "something" | lolcat'


# Remove old and unreferenced packages.
nix-collect-garbage
nix-store --gc
# Do the same for specific profiles.
nix-env -p '/nix/var/nix/profiles/per-user/jonah/profile' --delete-generations 'old'
nix-env -p '/nix/var/nix/profiles/per-user/sam/profile' --delete-generations '14d'

# Delete old roots.
# Removes the ability to roll back to the deleted ones.
nix-collect-garbage --delete-old
nix-collect-garbage -d --dry-run


# Evaluate Nix expressions in an interactive session.
nix repl

# Evaluate Nix expressions from files.
# The file path defaults to 'default.nix'.
nix-instantiate --eval
nix-instantiate --eval 'path/to/file.nix'


# Scan the entire store for corrupt paths.
nix-store --verify --check-contents --repair

# Replace identical files with hard links.
# It can take quite a while to finish.
nix-store --optimise
```

</details>

## Further readings

- [Website]
- [NixOS]
- [Guix]

### Sources

- [Manual]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[guix]: guix.md
[nixos]: nixos.md

<!-- Upstream -->
[manual]: https://nix.dev/manual/nix/2.19/
[website]: https://nix.dev
