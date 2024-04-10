# Kustomize

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation</summary>

[`kubectl`][kubectl] comes [with an embedded version of Kustomize](https://github.com/kubernetes-sigs/kustomize/blob/master/README.md#kubectl-integration).

```sh
brew install 'kustomize'
zypper install 'kustomize'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Build.
kustomize build
kustomize build 'path/to/folder' --enable_managedby_label
kustomize build 'github.com/kubernetes-sigs/kustomize/examples/multibases/dev/?ref=v1.0.6'
kubectl kustomize
kubectl kustomize 'path/to/helm/enabled/folder' --enable-helm

# Validate.
kustomize build | kubectl apply --filename - --validate --dry-run=client
kubeval <(kustomize build)

# Deploy.
kustomize build | kubectl apply --filename -
kubectl apply -f <(kubectl kustomize --enable-helm)
```

</details>

## Further readings

- [Website]
- [Github]
- [Reference]
- [`kubectl`][kubectl]

### Sources

- [Kustomization of a helm chart]
- [Examples]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[kubectl]: kubectl.md

<!-- Files -->
<!-- Upstream -->
[examples]: https://github.com/kubernetes-sigs/kustomize/blob/master/examples/README.md
[github]: https://github.com/kubernetes-sigs/kustomize
[kustomization of a helm chart]: https://github.com/kubernetes-sigs/kustomize/blob/master/examples/chart.md
[reference]: https://kubectl.docs.kubernetes.io/references/kustomize/
[website]: https://kustomize.io/

<!-- Others -->
