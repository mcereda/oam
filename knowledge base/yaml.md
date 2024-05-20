# YAML

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

There is no key naming convention.<br/>
Best practice is to use the one used by the users or tools using that file (e.g.: Kubernetes --> camelCase, CircleCI -->
snake_case, Jenkins --> kebab-case).

```yaml
---
# This is a comment
string: this is a string
number: 0
truthy: true
list:
  - element
  - element
object:
  key: value
  nested:
    can: do
    lists:
      - too
"key:with:chars": requiring quotation
```

## Further readings

- [yaml-multiline.info]
- [`yamllint`][yamllint]
- [What is the canonical YAML naming style]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[yamllint]: yamllint.md

<!-- Others -->
[what is the canonical yaml naming style]: https://stackoverflow.com/questions/22771226/what-is-the-canonical-yaml-naming-style
[yaml-multiline.info]: https://yaml-multiline.info
