# `ripsecrets`

Command-line tool to prevent committing secret keys into source code.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
brew install 'ripsecrets'
cargo install --git 'https://github.com/sirwart/ripsecrets' --branch 'main'
```

</details>

<details>
  <summary>Usage</summary>

```sh
ripsecrets
ripsecrets 'path/to/file.1' 'file2' 'dir1'
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

- [`detect-secrets`][detect-secrets]
- [gitleaks]
- [trufflehog]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[detect-secrets]: detect-secrets.md
[gitleaks]: gitleaks.md
[trufflehog]: trufflehog.md

<!-- Files -->
<!-- Upstream -->
[main repository]: https://github.com/sirwart/ripsecrets

<!-- Others -->
