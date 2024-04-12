# Kubeconform

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation</summary>

```sh
brew install 'kubeconform'
```

</details>

<details>
  <summary>Usage</summary>

```sh
kubeconform 'manifest.yaml'
kubeconform -verbose -skip 'AWX' -summary 'manifest.yaml'
kubeconform … -n $(nproc) \
  -schema-location 'default' \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  'manifest.yaml'
```

</details>

<!-- Uncomment if needed
<details>
  <summary>Real world use cases</summary>
</details>
-->

## Further readings

- [Github]
- [`kubeconform-helm`][kubeconform-helm]

### Sources

- [`kubeval`][kubeval]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[kubeval]: kubeval.md

<!-- Files -->
<!-- Upstream -->
[github]: https://github.com/yannh/kubeconform

<!-- Others -->
[kubeconform-helm]: https://github.com/jtyr/kubeconform-helm
