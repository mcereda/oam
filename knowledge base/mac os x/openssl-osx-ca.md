# openssl-osx-ca

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install and configure.
brew tap homebrew/services
brew tap raggi/ale
brew install openssl-osx-ca
brew services start openssl-osx-ca

# Run manually.
openssl-osx-ca

# Check the last time the certificates file changed.
stat "$(brew --prefix)/etc/openssl@"*"/cert.pem"
find "$(brew --prefix)/etc" -type 'f' -name 'cert.pem' -path '*/openssl*' -exec stat {} +
```

## Further readings

- [Homebrew]

## Sources

- [openssl-osx-ca]

<!-- project's references -->
[openssl-osx-ca]: https://github.com/raggi/openssl-osx-ca

<!-- internal references -->
[homebrew]: homebrew.md
