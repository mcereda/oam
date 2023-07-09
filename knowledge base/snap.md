# Snap

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Manage revisions](#manage-revisions)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Find snaps.
snap find chezmoi
snap find --private boincstats-js
snap search vscode

# View detailed information about snaps.
snap info snapd

# Download snaps and their assertions without installing them
snap download constellation

# Install snaps.
sudo snap install karuta
sudo snap install code-tray --channel=beta
snap ack foo.assert && snap install foo.snap
snap install --dangerous foo.snap
snap install --devmode foo
snap install --classic foo

# List installed snaps.
snap list
snap list --all

# Manually update snaps.
sudo snap refresh
sudo snap refresh awdur
sudo snap refresh mist --channel=beta

# Revert snaps to a prior version.
sudo snap revert widl-nan
sudo snap revert bunyan --revision 5

# Remove snaps.
sudo snap remove runjs

# Remove all old revisions of all installed snaps.
snap list --all \
  | grep disabled | awk '{print $3, $1}' \
  | xargs -I {} -t sh -c "sudo snap remove --purge --revision {}"

# Log in/out to/from snap.
sudo snap login
snap logout

# View transaction logs.
snap changes
snap change 123

# Watch transactions.
snap watch 123

# Abort transactions.
snap abort 123

# View available snap interfaces.
snap interfaces

# Connect a plug to the ubuntu core slot.
snap connect foo:camera :camera

# Disconnect a plug from the ubuntu core slot.
snap disconnect foo:camera

# Disable snaps.
snap disable foo

# Enable snaps.
snap enable foo

# Set a snap's properties.
snap set foo bar=10

# Read a snap's current properties.
snap get foo bar
```

## Manage revisions

```sh
# List installed snaps with all their revisions.
snap list --all

# Remove all old revisions of all installed snaps.
snap list --all \
  | grep disabled | awk '{print $3, $1}' \
  | xargs -I {} -t sh -c "sudo snap remove --purge --revision {}"
```

## Further readings

- [cheat.sh]
- [Managing Ubuntu snaps]

<!--
  References
  -->

<!-- Others -->
[cheat.sh]: https://cheat.sh/snap
[managing ubuntu snaps]: https://www.freecodecamp.org/news/managing-ubuntu-snaps/
