# Gopass

## TL;DR

```shell
gopass init

# multistore init
gopass init --store private --path ~/.password-store.private
gopass init --store work    --path ~/.password-store.work
```

## Browsers integration

### Browserpass

```shell
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
