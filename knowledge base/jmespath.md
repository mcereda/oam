# JMESPath

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Filter elements in a list.
az devops user list --org 'https://dev.azure.com/organizationName' \
  --query "
    items[?
      startsWith(user.principalName, 'yourNameHere') &&
      \! contains(accessLevel.licenseDisplayName, 'Test plans')
    ].user.displayName
  "
aws … --query "locations[?name.contains(@, `le`)]"
aws … --query "locations[?name.contains(@, `ue`) || name.contains(@, `ia`)]"

#
aws ecs describe-tasks --cluster 'staging' --tasks 'ef6260ed8aab49cf926667ab0c52c313' --output 'yaml' \
  --query 'tasks[0] | {
      "managedAgents": containers[].managedAgents[?@.name==`ExecuteCommandAgent`][],
      "enableExecuteCommand": enableExecuteCommand
    }'

# Print an object with specific keys and values from the input.
az disk-encryption-set show --ids 'id' \
  --query "{
    \"keyId\": activeKey.keyUrl,
    \"accessPolicyId\": join('/', [activeKey.sourceVault.id, 'objectId', identity.principalId])
  }"
```

## Further readings

- [Website]
- [Specifications]

### Sources

- [Filtering JMESPath with contains]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[specifications]: https://jmespath.org/specification.html
[website]: https://jmespath.org/

<!-- Others -->
[filtering jmespath with contains]: https://stackoverflow.com/questions/50774937/filtering-jmespath-with-contains#50831828
