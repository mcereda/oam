# JSONata

> TODO

JSON query and transformation language.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```plaintext
# Concatenate strings
someAttribute & 'someSuffix'
'somePrefix' & someAttribute
'somePrefix' & someAttribute & 'someSuffix'

# Join strings
$join(['somePrefix', someAttribute, 'someSuffix'], '-')

# Filter array of objects by attribute's value
users[role = "admin"]
users[role = "admin" and name = "Alice"].name

# Filter events with timestamp value in the last week
events[$toMillis(timestamp) >= $toMillis($now()) - (60 * 60 * 7 * 24 * 1000)]

# Get a random value between 0 included and 1 excluded (0<=X<1)
$random()

# Get a random object from a list
# Lists are 0-indexed
users[$floor($random()*$count($users))]
```

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/jsonata-js/jsonata
[Documentation]: https://docs.jsonata.org/
[Website]: https://jsonata.org/

<!-- Others -->
