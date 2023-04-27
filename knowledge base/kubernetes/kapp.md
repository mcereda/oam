# Kapp

## TL;DR

```sh
# Configurations picked up from a directory
$ kapp deploy -a my-app -f ./examples/simple-app-example/config-1.yml

# Can be used with helm charts, removing need for Tiller
$ kapp -y deploy -a my-chart -f <(helm template my-chart --values my-vals.yml)

# … and with kustomize
$ kapp -y deploy -a my-app -f <(kustomize build ./my-app)

# … or templated with ytt
$ kapp -y deploy -a my-app -f <(ytt -f ./examples/simple-app-example/config-1.yml)
```

## Further readings

- Official [website]

[website]: https://get-kapp.io
