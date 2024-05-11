# Gopass

1. [TL;DR](#tldr)
1. [File formats](#file-formats)
1. [Browsers integration](#browsers-integration)
   1. [Browserpass](#browserpass)
1. [Troubleshooting](#troubleshooting)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Installation.
brew install 'gopass'
go install 'github.com/gopasspw/gopass@latest'
go install 'github.com/gopasspw/gopass@v1.15.11'

# Install shell completions.
gopass completion 'fish' > "$HOME/.config/fish/completions/gopass.fish"
source $(gopass completion 'zsh')

# Setup new stores.
# If no options are given, defaults are used.
gopass setup

# Show all configuration values.
gopass config
gopass config --store 'family'

# Show specific configuration values only.
gopass config 'core.autoclip'
gopass config --store='foo' 'core.autopush'

# Update specific configuration values.
gopass config 'core.autopush' false
gopass config --store 'bar' 'generate.generator' 'xkcd'

# Initialize the *root* store.
gopass init
gopass init -p 'path/to/root/store' 'key-id'

# Generate and show passwords in output.
gopass pwgen
gopass pwgen -1 24
gopass pwgen -x --xc --xl 'en' --xn --xs '-' 3

# List entries.
gopass list

# Interactively create secrets.
gopass create
gopass new

# Insert new entries.
gopass insert 'path/to/secret'
gopass insert -m …

# Create new entries with generated passwords.
gopass generate 'path/to/secret'
gopass generate -g 'xkcd' --lang 'en' 'path/to/secret'

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
gopass mounts 'internal/path/to/store' 'external/path/to/store'
gopass mounts add …
gopass mounts mount …

# Create and mount stores.
gopass mounts add -c 'internal/path/to/store' 'external/path/to/store'
gopass init -s 'store' -p 'path/to/store'

# Remove (a.k.a unmount) stores.
gopass mounts remove 'internal/path/to/store-1' … 'store-N'
gopass mounts rm …
gopass mounts unmount …
gopass mounts umount …


# List templates.
gopass templates
gopass templates 'path/to/folder'

# Show templates.
gopass templates show 'path/to/folder'
gopass templates cat …

# Create templates.
gopass templates edit 'path/to/folder'
gopass templates create …
gopass templates new …

# Use templates to create new secrets.
gopass edit -c 'path/to/folder/with/template'/'secret'

# Remove templates.
gopass templates remove 'path/to/folder'
gopass templates rm …


# List all recipients.
gopass recipients

# Get the key ID in the format used by gopass.
gpg --list-keys --keyid-format '0xlong'

# Add recipients.
gopass recipients add 'key-id-in-0xlong-format'
gopass recipients add --store 'store' …

# Remove recipients
gopass recipients remove
gopass recipients remove '0xB5B44266A3683834'
gopass recipients remove --store 'store' …


# Check the stores integrity, clean up artifacts and re-encrypt secrets if
# recipients are missing or changed.
gopass fsck
gopass fsck --decrypt


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

### Sources

- [BrowserPass extension installation guide]
- [Configuration][config]

<!--
  References
  -->

<!-- Upstream -->
[config]: https://github.com/gopasspw/gopass/blob/master/docs/config.md
[documentation]: https://github.com/gopasspw/gopass/tree/master/docs
[faq]: https://github.com/gopasspw/gopass/blob/master/docs/faq.md
[features]: https://github.com/gopasspw/gopass/blob/master/docs/features.md
[secrets]: https://github.com/gopasspw/gopass/blob/master/docs/secrets.md
[website]: https://www.gopass.pw/

<!-- Others -->
[browserpass extension installation guide]: https://github.com/browserpass/browserpass-extension#
[woile's cheatsheet]: https://woile.github.io/gopass-cheat-sheet/
