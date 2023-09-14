# Flux

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Check the extension is enabled.
kubectl -n 'flux-system' get extensionconfig 'fluxextension'

# Check the configuration is rolled out and properly configured.
kubectl -n 'default' get fluxconfig 'baseline-configuration'
```

## Further readings

- [Website]
- [Kubernetes]
- [The GitOps approach][gitops]

<!--
  References
  -->

<!-- Upstream -->
[website]: https://fluxcd.io/

<!-- Knowledge base -->
[gitops]: ../gitops.md
[kubernetes]: README.md
