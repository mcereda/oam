# JMESPath

## TL;DR

```sh
# Filter elements in a list.
az devops user list \
  --org https://dv.azure.com/organizationName \
  --query "\
    items[? \
      startsWith(user.principalName, 'yourNameHere') && \
      \! contains(accessLevel.licenseDisplayName, 'Test plans') \
    ].user.displayName"
```

## Further readings

- [Website]

[specifications]: https://jmespath.org/specification.html
[website]: https://jmespath.org/
