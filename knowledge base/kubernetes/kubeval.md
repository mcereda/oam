# Kubeval

Validates one or more Kubernetes configuration files.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
$ kubeval 'my-invalid-rc.yaml' || echo "Validation failed" >&2
WARN - my-invalid-rc.yaml contains an invalid ReplicationController - spec.replicas: Invalid type. Expected: integer, given: string
Validation failed
```

## Further readings

- [Kubeval]

## Sources

- [Validating kubernetes YAML files with kubeval]

All the references in the [further readings] section, plus the following:

<!-- project's references -->
[kubeval]: https://www.kubeval.com

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
[kubernetes]: README.md

<!-- external references -->
[validating kubernetes yaml files with kubeval]: https://learnk8s.io/validating-kubernetes-yaml#kubeval
