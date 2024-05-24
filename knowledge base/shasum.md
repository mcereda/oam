# Shasum

1. [TL;DR](#tldr)

## TL;DR

<details>
  <summary>Installation and configuration</summary>

```sh
brew install 'coreutils'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Print the checksum of given files.
sha512sum 'path/to/file'
sha1sum 'path/to/file.1' 'path/to/file.N'

# Check files given their checksum and name in one or more files.
sha256sum -c 'expected.sha256'
sha512sum -cw 'expected.1.sha512' 'expected.N.sha512'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>
</details>
-->

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
