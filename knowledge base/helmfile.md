# Helmfile

1. [TL;DR](#tldr)

## TL;DR

```sh
# Show what happens in the internal computations.
helmfile --debug -e environment apply

# Show the difference between the current state and what would be applied.
# Requires `helm` to have the 'diff' plugin installed.
helmfile
  -f custom.yml
  -e environment
  diff
    --values environment.yaml
```
