# Flux

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Install Flux on clusters.
flux check --pre && flux install

# Check the status of Flux's controllers and CRDs.
flux check

# Check the cluster extension is enabled.
kubectl -n 'flux-system' get extensionconfig 'fluxextension'

# Create resources.
flux create source git 'base' --url 'https://github.com/user/repo' \
  --branch 'main' --interval '5m'
flux create kustomization 'base' --source 'base' --path '/' --prune true \
  --interval '3m' --health-check 'Deployment/name' --health-check-timeout '2m'

# Check the flux configuration is rolled out and properly configured.
kubectl -n 'default' get fluxconfig 'configuration-name'
kubectl get fluxconfig 'baseline' -o jsonpath='{.spec.gitRepository.ref.branch}'

# Check resources of configurations.
flux get -A all
flux get source git 'source-name'
flux -n 'default' get kustomization 'kustomization-name'

# Reconcile resources.
flux reconcile kustomization 'kustomization-name' --with-source
flux -n 'default' reconcile kustomization 'kustomization-name'

# Export resources.
flux export source git --all > 'sources.all.yaml'
flux export -n 'default' source oci 'source-name' > 'src.name.oci.default.yaml'

# Delete resources.
flux delete kustomization 'base'
flux delete source git 'base'

# Uninstall Flux and its CRDs.
flux uninstall
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
