# Trufflehog

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install 'trufflehog'
docker pull 'trufflesecurity/trufflehog:latest'
```

</details>

<details>
  <summary>Usage</summary>

```sh
trufflehog git 'https://github.com/trufflesecurity/test_keys' --only-verified

docker run --rm -it -v "$PWD:/pwd" 'trufflesecurity/trufflehog:latest' \
  github --repo 'https://github.com/trufflesecurity/test_keys'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Main repository]

Alternatives:

- [`detect-secrets`][detect-secrets]
- [gitleaks]
- [`ripsecrets`][ripsecrets]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[detect-secrets]: detect-secrets.md
[gitleaks]: gitleaks.md
[ripsecrets]: ripsecrets.md

<!-- Files -->
<!-- Upstream -->
[main repository]: https://github.com/trufflesecurity/trufflehog
[website]: https://trufflesecurity.com/

<!-- Others -->
