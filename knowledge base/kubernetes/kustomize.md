# Kustomize

FIXME

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# validation
kustomize build ${PROJECT} | kubectl apply --filename - --validate --dry-run=client
kubeval <(kustomize build ${PROJECT})

# deployment
kustomize build ${PROJECT} | kubectl apply --filename -
```

## Further readings

- [Website]
- [Github]

## Sources

All the references in the [further readings] section, plus the following:

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/kubernetes-sigs/kustomize
[website]: https://kustomize.io/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
<!-- Files -->
<!-- Others -->
