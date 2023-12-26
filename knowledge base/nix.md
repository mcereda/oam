# The Nix package manager

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install Nix.
# Works on Linux *using systemd* with SELinux *disabled*. Or MacOSX.
curl -L 'https://nixos.org/nix/install' | sh
bash <(curl -L 'https://nixos.org/nix/install') --daemon
bash <(curl -L 'https://nixos.org/nix/install') --no-daemon


# List configured channels.
nix-channel --list

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

# Free up space occupied by unreachable store objects like packages used in
# temporary shell environments.
nix-collect-garbage
nix-collect-garbage --delete-old
nix-collect-garbage -d --dry-run
nix-store --gc


# Evaluate Nix expressions in an interactive session.
nix repl

# Evaluate Nix expressions from files.
# The file path defaults to 'default.nix'.
nix-instantiate --eval
nix-instantiate --eval 'path/to/file.nix'
```

## Further readings

- [Website]
- [NixOS]

## Sources

All the references in the [further readings] section, plus the following:

- [Manual]

<!--
  References
  -->

<!-- Upstream -->
[manual]: https://nix.dev/manual/nix/2.19/
[website]: https://nix.dev

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[nixos]: nixos.placeholder
