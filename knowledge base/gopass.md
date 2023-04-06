# Gopass

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [File formats](#file-formats)
1. [Browsers integration](#browsers-integration)
   1. [Browserpass](#browserpass)
1. [Troubleshooting](#troubleshooting)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Setup new stores.
# If no options are given, defaults are used.
gopass setup

# Show all configuration values.
gopass config

# Show specific configuration values only.
gopass config 'core.autoclip'

# Update specific configuration values.
gopass config 'core.autoclip' false

# Initiate the *root* store.
gopass init
gopass init -p 'path/to/root/store' 'key-id'

# List entries.
gopass list

# Interactively create secrets.
gopass create
gopass new

# Insert new entries.
gopass insert 'path/to/secret'
gopass insert -m …

# Copy secrets' password to the clipboard.
# Do *not* print secrets out.
gopass show -c 'path/to/secret'

# Edit new or existing secrets.
gopass edit 'path/to/secret'
gopass set …

# Delete entries.
gopass delete 'path/to/secret'
gopass remove -r …
gopass rm …

# Copy entries.
gopass copy 'from' 'to'
gopass cp …

# Move entries.
gopass move 'from' 'to'
gopass mv …

# Link entries.
gopass link 'from' 'to'
gopass ln …

# Copy files.
gopass fscopy '/path/to.file' 'path/to/secret'
gopass fscopy 'path/to/secret' '/path/to.file'

# Copy files and remove the source.
gopass fsmove '/path/to.file' 'path/to/secret'
gopass fsmove 'path/to/secret' '/path/to.file'

# Get sha256sum of secrets.
gopass sum 'path/to/secret'
gopass sha …
gopass sha265 …

# Find entries matching the search string.
gopass find 'github'
gopass search …

# Find secrets containing the search string when decrypted.
gopass grep 'search-string'

# List mounted stores.
gopass mounts

# Add (a.k.a mount) existing stores in multi store mode.
# Default command for 'mounts' if missing.
gopass mounts 'store' 'path/to/store'
gopass mounts add …
gopass mounts mount …

# Create and mount stores.
gopass mounts add -c 'store' 'path/to/store'
gopass init -s 'store' -p 'path/to/store'

# Remove (a.k.a unmount) stores.
gopass mounts remove 'store-1' … 'store-N'
gopass mounts rm …
gopass mounts unmount …
gopass mounts umount …

# List all recipients.
gopass recipients

# Add recipients.
gopass recipients add 'key-id'
gopass recipients add -s 'store' …

# Remove recipients
gopass recipients remove '0xB5B44266A3683834'
gopass recipients remove -s 'store' …

# Check the stores integrity, clean up artifacts and re-encrypt secrets if
# recipients are missing.
gopass fsck

# Sync with remotes.
gopass sync
gopass sync -s 'store-1' … 'store-N'

# Manage git operations manually.
gopass git pull
gopass git push --store='foo' 'origin' 'main'

# Reset gopass' configuration.
rm "${HOME}/.config/gopass/config"

# Remove gopass' default root store.
rm -r "${HOME}/.local/share/gopass/stores/root"
```

## File formats

See [secrets], but mostly [features].

## Browsers integration

### Browserpass

```sh
brew tap amar1729/formulae
brew install browserpass
for b in chromium chrome vivaldi brave firefox; do
  PREFIX='/usr/local/opt/browserpass' make hosts-chrome-user -f /usr/local/opt/browserpass/lib/browserpass/Makefile
done
```

## Troubleshooting

See the [FAQ] page.

## Further readings

- GoPass' [website]
- GoPass' [documentation]
- [woile's cheatsheet]

## Sources

All the references in the [further readings] section, plus the following:

- [BrowserPass extension installation guide]

<!-- project's references -->
[config]: https://github.com/gopasspw/gopass/blob/master/docs/config.md
[documentation]: https://github.com/gopasspw/gopass/tree/master/docs
[faq]: https://github.com/gopasspw/gopass/blob/master/docs/faq.md
[features]: https://github.com/gopasspw/gopass/blob/master/docs/features.md
[secrets]: https://github.com/gopasspw/gopass/blob/master/docs/secrets.md
[website]: https://www.gopass.pw/

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
[browserpass extension installation guide]: https://github.com/browserpass/browserpass-extension#
[woile's cheatsheet]: https://woile.github.io/gopass-cheat-sheet/
