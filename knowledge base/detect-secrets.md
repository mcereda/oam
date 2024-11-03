# `detect-secrets`

Python module for detecting secrets within code bases.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install 'detect-secrets'
pip install 'detect-secrets'
```

</details>

<details>
  <summary>Usage</summary>

```sh
detect-secrets scan
detect-secrets scan --exclude-lines 'password = (blah|fake)' --exclude-files '.*\.signature$'
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

- [Main repository]

Alternatives:

- [gitleaks]
- [`ripsecrets`][ripsecrets]
- [trufflehog]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[gitleaks]: gitleaks.md
[ripsecrets]: ripsecrets.md
[trufflehog]: trufflehog.md

<!-- Files -->
<!-- Upstream -->
[main repository]: https://github.com/Yelp/detect-secrets

<!-- Others -->
