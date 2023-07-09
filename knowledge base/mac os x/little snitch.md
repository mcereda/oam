# Little Snitch

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Sort the remotes in a rules list.
jq -r '[.rules[] | .remote, ."remote-domains", ."remote-hosts" | select(. != null)] | sort | .[]' rules.lsrules

# Sort the rules by their 'remote', 'remote-domains' or 'remote-hosts' field.
FIXME
```

## Further readings

- [The .lsrules file format]

<!--
  References
  -->

<!-- Upstream -->
[the .lsrules file format]: https://help.obdev.at/littlesnitch5/ref-lsrules-file-format
