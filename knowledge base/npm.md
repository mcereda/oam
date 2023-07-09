# Node Package Manager CLI

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Disable SSL verification.
npm config set 'strict-ssl'='false'

# Use a custom CA certificate.
npm config set 'cafile'='path/to/ca/cert.pem'

# Install packages.
npm install '@pnp/cli-microsoft365'
npm install -g '@pnp/cli-microsoft365@latest'

# Remove packages.
npm uninstall '@pnp/cli-microsoft365'
```

## Further readings

- Official [documentation]
- [node.js]

<!--
  References
  -->

<!-- Upstream -->
[documentation]: https://docs.npmjs.com/cli/

<!-- Knowledge base -->
[node.js]: node.js.md
