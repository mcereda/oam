# Yamllint

A linter for YAML files written in Python and compatible with Python 3 only.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Use a specific configuration file.
yamllint -c /path/to/config file.yaml

# Pass custom configuration options on the CLI.
yamllint -d "{extends: relaxed, rules: {line-length: {max: 120}}}" file.yaml
```

## Configuration

`yamllint` uses a set of [rules] to check YAML files for problems. Each rule is independent from the others, and can be enabled, disabled or tweaked. All these settings can be gathered in a configuration file.

To use a custom configuration file, use the `-c` option:

```sh
yamllint -c /path/to/config file.yaml
```

If no such option is provided, `yamllint` will look for a configuration file in the following locations (by order of preference):

- `.yamllint`, `.yamllint.yaml` or `.yamllint.yml` in the current working directory
- the file referenced by `$YAMLLINT_CONFIG_FILE`, if set
- `$XDG_CONFIG_HOME/yamllint/config`
- `~/.config/yamllint/config`

Finally, if no config file is found the default configuration is applied.

You can avoid the need to redefine every rule when writing a custom configuration file `extend`ing the default one or any other already-existing configuration file:

```yaml
extends: default
rules:
  comments-indentation: disable   # don't bother me at all with this rule
```

```yaml
extends: relaxed
  line-length:   # just warn if a line is longer than 120 chars, instead of failing at 81
    max: 120
    level: warning
  indentation:   # loosen up on block sequences indentation
    indent-sequences: whatever
```

[Configuration file example].

## Further readings

- [GitHub] page
- Yamllint's [documentation]
- [Rules]

<!--
  References
  -->

<!-- Upstream -->
[documentation]: https://yamllint.readthedocs.io/en/stable
[github]: https://github.com/adrienverge/yamllint
[rules]: https://yamllint.readthedocs.io/en/stable/rules.html

<!-- Files -->
[configuration file example]: ../examples/dotfiles/.yamllint.yaml
