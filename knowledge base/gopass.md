# Gopass

## TL;DR

```sh
# Initiate the root store.
gopass init
gopass init -p 'path/to/root/store'

# Insert new entries.
gopass insert 'path/to/secret'
gopass insert 'path/to/secret' -m

# Edit new or existing secrets.
gopass edit 'path/to/secret'
gopass set 'path/to/secret'

# Delete entries.
gopass delete 'path/to/secret'
gopass remove 'path/to/secret'
gopass rm 'path/to/secret'

# List mounted stores.
gopass mounts

# Add (a.k.a mount) existing stores in multi store mode.
gopass mounts add 'archive' '.password-store.archive'
gopass mounts mount 'test' '.password-store.test'

# Create and mount stores.
gopass init --store 'private' --path '.password-store.private'
gopass init --store 'work' --path '.password-store.work'

# Remove (a.k.a unmount) stores.
gopass mounts remove 'test' '.password-store.test'
gopass mounts rm 'test' '.password-store.test'
gopass mounts unmount 'archive' '.password-store.archive'
gopass mounts umount 'archive' '.password-store.archive'

# Reset gopass' configuration.
rm "${HOME}/.config/gopass/config"

# Remove gopass' default root store.
rm -r "${HOME}/.local/share/gopass/stores/root"
```

## Browsers integration

### Browserpass

```sh
brew tap amar1729/formulae
brew install browserpass
for b in chromium chrome vivaldi brave firefox; do
  PREFIX='/usr/local/opt/browserpass' make hosts-chrome-user -f /usr/local/opt/browserpass/lib/browserpass/Makefile
done
```

## Further readings

- GoPass [features]
- [BrowserPass extension installation guide]

[features]: https://github.com/gopasspw/gopass/blob/master/docs/features.md

[browserpass extension installation guide]: https://github.com/browserpass/browserpass-extension#installation
