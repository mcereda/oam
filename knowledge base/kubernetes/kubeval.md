# Kubeval

Validates one or more Kubernetes configuration files.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Usage](#usage)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Installation.
asdf plugin add 'kubeval' && asdf install 'kubeval' '0.16.0'
brew tap 'instrumenta/instrumenta' && brew install 'kubeval'
docker run -v "${PWD}/dir:/dir" 'garethr/kubeval' 'dir/file.yaml'
scoop bucket add 'instrumenta' 'https://github.com/instrumenta/scoop-instrumenta' && scoop install 'kubeval'

# Usage.
kubeval 'manifest_file.yaml' || echo "Validation failed" >&2
kubeval <(helm template …)
kubeval <(kustomize build …)
```

## Usage

```sh
$ kubeval 'my-invalid-rc.yaml' || echo "Validation failed" >&2
WARN - my-invalid-rc.yaml contains an invalid ReplicationController - spec.replicas: Invalid type. Expected: integer, given: string
Validation failed
```

## Further readings

- [Website]
- [Github]

## Sources

All the references in the [further readings] section, plus the following:

- [Validating kubernetes YAML files with kubeval]

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/instrumenta/kubeval/
[website]: https://www.kubeval.com

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[kubernetes]: README.md

<!-- Others -->
[validating kubernetes yaml files with kubeval]: https://learnk8s.io/validating-kubernetes-yaml#kubeval
