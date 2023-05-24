# Little Snitch

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Sort the remotes in a rules list.
jq -r '[.rules[] | .remote, ."remote-domains", ."remote-hosts" | select(. != null)] | sort | .[]' rules.lsrules

# Sort the rules by their 'remote', 'remote-domains' or 'remote-hosts' field.
FIXME
```

## Further readings

- [The .lsrules file format]

## Sources

All the references in the [further readings] section, plus the following:

<!-- project's references -->
[the .lsrules file format]: https://help.obdev.at/littlesnitch5/ref-lsrules-file-format

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
<!-- external references -->
