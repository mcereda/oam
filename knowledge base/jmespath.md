# JMESPath

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Filter elements in a list.
az devops user list --org 'https://dev.azure.com/organizationName' \
  --query "
    items[?
      startsWith(user.principalName, 'yourNameHere') &&
      \! contains(accessLevel.licenseDisplayName, 'Test plans')
    ].user.displayName"

# Print an object with specific keys and values from the input.
az disk-encryption-set show --ids 'id' \
  --query "{
    \"keyId\": activeKey.keyUrl,
    \"accessPolicyId\": join('/', [activeKey.sourceVault.id, 'objectId', identity.principalId])
  }"
```

## Further readings

- [Website]

<!--
  References
  -->

<!-- Upstream -->
[specifications]: https://jmespath.org/specification.html
[website]: https://jmespath.org/
