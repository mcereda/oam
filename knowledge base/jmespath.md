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

# Sort elements in a list.
# Refer <https://jmespath.org/specification.html#sort-by>.
# Ascending. Use `reverse(sort_by(…))` to get the list in descending order.
# Refer <https://jmespath.org/specification.html#reverse>.
aws ec2 describe-images --filters 'Name=tag:Name,Values=[RunnerBaseline]' \
  --query 'sort_by(Images, &LastLaunchedTime)[]'

# Slice arrays.
# Refer <https://jmespath.org/specification.html#slices>.
aws ec2 describe-images … --query 'Images[]'       # all elements
aws ec2 describe-images … --query 'Images[3:]'     # elements from 4th onwards
aws ec2 describe-images … --query 'Images[:6]'     # elements from 1st to 5th
aws ec2 describe-images … --query 'Images[1:4]'    # elements from 2nd to 5th
aws ec2 describe-images … --query 'Images[5:9:2]'  # odd elements from 5th to 9th
aws ec2 describe-images … --query 'Images[-3:]'    # the last 3 elements
aws ec2 describe-images … --query 'Images[::-1]'   # all elements in reverse order
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
