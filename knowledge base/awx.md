# Ansible AWX

1. [TL;DR](#tldr)
1. [Installation](#installation)
1. [Testing](#testing)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<!-- Uncomment if needed
<details>
  <summary>Installation and configuration</summary>
</details>
-->

<!-- Uncomment if needed
<details>
  <summary>Usage</summary>
</details>
-->

<!-- Uncomment if needed
<details>
  <summary>Real world use cases</summary>
</details>
-->

## Installation

Starting from version 18.0, the [AWX Operator][operator's documentation] is the preferred way to install AWX.<br/>
It is meant to provide a Kubernetes-native installation method for AWX via an AWX Custom Resource Definition (CRD).

## Testing

```sh
$ minikube start --cpus=4 --memory=6g --addons=ingress
…
🌟  Enabled addons: storage-provisioner, default-storageclass, ingress
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

```

## Further readings

- [Website]
- [Kubernetes]
- [Minikube]

### Sources

- [AWX's documentation]
- [AWX's repository]
- [Operator's documentation]
- [Operator's repository]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[kubernetes]: kubernetes/README.md
[minikube]: kubernetes/minikube.md

<!-- Files -->
<!-- Upstream -->
[awx's documentation]: https://ansible.readthedocs.io/projects/awx/en/latest/
[awx's repository]: https://github.com/ansible/awx/
[operator's documentation]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/
[operator's repository]: https://github.com/ansible/awx-operator/
[website]: https://www.ansible.com/awx/

<!-- Others -->
