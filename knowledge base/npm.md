# Node Package Manager CLI

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Disable SSL verification.
npm config set 'strict-ssl'='false'

# Use custom CA certificates.
npm config set 'cafile'='path/to/ca/cert.pem'
```

</details>

<details>
  <summary>Usage</summary>

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

# Update packages.
npm update
npm up --save

# Remove packages.
npm uninstall '@pnp/cli-microsoft365'
```

</details>

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
