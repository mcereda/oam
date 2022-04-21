# Kubeval

Validates one or more Kubernetes configuration files.

## TL;DR

```shell
$ kubeval my-invalid-rc.yaml || echo "Validation failed" >&2
WARN - my-invalid-rc.yaml contains an invalid ReplicationController - spec.replicas: Invalid type. Expected: integer, given: string
Validation failed
```

## Further readings

- [Kubeval]
- [Validating kubernetes YAML files with kubeval]

[kubeval]: https://www.kubeval.com
[validating kubernetes yaml files with kubeval]: https://learnk8s.io/validating-kubernetes-yaml#kubeval
