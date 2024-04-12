# Kubeval

<div class="alert" style="
  background-color: rgba(255,0,0,0.0625);
  border: solid tomato;  /* #FF6347 */
  margin: 1em 0;
  padding: 1em 1em 0;
">
<header style="
  font-weight: bold;
  margin-bottom: 0.5em;
">Deprecated</header>

Check out [`kubeconform`][kubeconform] or other tools.

</div>

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
- [Kubernetes]
- [`kubeconform`][kubeconform]

### Sources

- [Validating kubernetes YAML files with kubeval]

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/instrumenta/kubeval/
[website]: https://www.kubeval.com

<!-- In-article sections -->
<!-- Knowledge base -->
[kubeconform]: kubeconform.md
[kubernetes]: README.md

<!-- Others -->
[validating kubernetes yaml files with kubeval]: https://learnk8s.io/validating-kubernetes-yaml#kubeval
