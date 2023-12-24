# Kapp

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Configurations picked up from a directory
$ kapp deploy -a 'my-app' -f './examples/simple-app-example/config-1.yml'

# Can be used with helm charts
$ kapp -y deploy -a 'my-chart' -f <(helm template 'my-chart' --values 'my-values.yml')

# … and with `kustomize`
$ kapp -y deploy -a 'my-app' -f <(kustomize build './my-app')

# … or templated with `ytt`
$ kapp -y deploy -a 'my-app' -f <(ytt -f './examples/simple-app-example/config-1.yml')
```

## Further readings

- [Website]

<!--
  References
  -->

<!-- Upstream -->
[website]: https://carvel.dev/kapp/
