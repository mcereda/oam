# Node Package Manager CLI

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Search for packages.
npm search 'typescript'

# Install packages.
# Use existing cache.
npm install '@pnp/cli-microsoft365'
npm i -g '@pnp/cli-microsoft365@latest'

# Install packages invalidating the current cache.
# Removes any existing 'node_modules'.
# Good for CI.
npm clean-install '@pnp/cli-microsoft365'
npm ci -g '@pnp/cli-microsoft365@latest'

# Remove packages.
npm uninstall '@pnp/cli-microsoft365'
```

```sh
# Disable SSL verification.
npm config set 'strict-ssl'='false'

# Use a custom CA certificate.
npm config set 'cafile'='path/to/ca/cert.pem'
```

## Further readings

- Official [documentation]
- [node.js]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[node.js]: node.js.md

<!-- Upstream -->
[documentation]: https://docs.npmjs.com/cli/
