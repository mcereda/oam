# `update-alternatives`

TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<!-- Uncomment if used
<details>
  <summary>Installation and configuration</summary>

```sh
```

</details>
-->

<details>
  <summary>Usage</summary>

```sh
# Get configured alternatives and their values.
update-alternatives --get-selections

# Show the full list of alternatives for commands.
update-alternatives --display 'java'

# *Interactively* change the default alternative for commands.
update-alternatives --config 'java'
update-alternatives --config --all
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

### Sources

- [`update-alternatives`: managing multiple versions of commands and files][update-alternatives: managing multiple versions of commands and files]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[update-alternatives: managing multiple versions of commands and files]: https://documentation.suse.com/sles/15-SP5/html/SLES-all/cha-update-alternative.html
