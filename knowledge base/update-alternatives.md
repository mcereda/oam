# `update-alternatives`

TODO

Intro

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

> Do **not** install custom alternatives for `python3` on SUSE systems.<br/>
> `/usr/bin/python3` does **not** have update alternatives there due to system tools dependencies and always points to
> specific tested versions. Creating custom `python3` alternatives pointing to different versions — i.e., `python3.11`
> — **will** break dependent system tools.

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
[update-alternatives: managing multiple versions of commands and files]: https://documentation.suse.com/sles/15-SP5/html/SLES-all/cha-update-alternative.html

<!-- Others -->
