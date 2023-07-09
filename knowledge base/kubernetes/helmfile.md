# Helmfile

Declarative spec for deploying helm charts.

Leverages `kubectl`.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Show what happens in the internal computations.
helmfile --debug -e 'environment' apply

# Show the difference between the current state and what would be applied.
# Requires `helm` to have the 'diff' plugin installed.
helmfile \
  -f 'custom.yml' \
  -e 'environment' \
  diff \
    --values 'environment.values.yaml'
```

## Further readings

- [Github]
- [Helm]
- [`kubectl`][kubectl]
- [Kubernetes]

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/helmfile/helmfile

<!-- Knowledge base -->
[helm]: helm.md
[kubectl]: kubectl.md
[kubernetes]: README.md
