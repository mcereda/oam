# Amazon Web Services

1. [Constraints](#constraints)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Constraints

| data type | component | summary                        | description                                                                                                                                                                                                                                                | type   | length   | pattern                           | required |
| --------- | --------- | ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | -------- | --------------------------------- | -------- |
| tag       | key       | Required name of the tag       | The string value can be Unicode characters and cannot be prefixed with "aws:".<br/>The string can contain only the set of Unicode letters, digits, white-space, `_`,' `.`, `/`, `=`, `+`, `-`, `:`, `@` (Java regex: `^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-]*)$`) | String | 1 to 128 | `^([\p{L}\p{Z}\p{N}_.:/=+\-@]*)$` | Yes      |
| tag       | value     | The optional value of the tag. | The string value can be Unicode characters. The string can contain only the set of Unicode letters, digits, white-space, `_`, `.`, `/`, `=`, `+`, `-`, `:`, `@` (Java regex: `^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-]*)$"`)                                        | String | 0 to 256 | `^([\p{L}\p{Z}\p{N}_.:/=+\-@]*)$` | Yes      |

## Further readings

### Sources

- [Constraints for tags][constraints  tag]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[constraints  tag]: https://docs.aws.amazon.com/directoryservice/latest/devguide/API_Tag.html

<!-- Others -->
