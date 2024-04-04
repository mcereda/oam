# Ansible AWX

1. [TL;DR](#tldr)
1. [Installation](#installation)
1. [Testing](#testing)
   1. [Create a demo instance on an ARM machine](#create-a-demo-instance-on-an-arm-machine)
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

### Create a demo instance on an ARM machine

<details>
  <summary>Run: follow the basic installation guide</summary>

[Guide][basic install]

```sh
$ minikube start --cpus=4 --memory=6g --addons=ingress
…
🌟  Enabled addons: storage-provisioner, default-storageclass, ingress
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

$ cd '/tmp'

$ # There was no ARM version of the 'kube-rbac-proxy' image upstream, so it was impossible to just use the `make deploy`
$ # command as explained in the basic install.
$ # Defaulting to use quay.io as repository as the ARM version of that image is available there.
$ cat <<EOF > 'kustomization.yaml'
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: awx
resources:
  - github.com/ansible/awx-operator/config/default?ref=2.14.0
    # https://github.com/ansible/awx-operator/releases
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.14.0   # same as awx-operator in resources
  - name: gcr.io/kubebuilder/kube-rbac-proxy
    # no ARM version upstream, defaulting to quay.io
    newName: quay.io/brancz/kube-rbac-proxy
    newTag: v0.16.0-arm64
EOF
$ kubectl apply -k '.'
namespace/awx created
…
deployment.apps/awx-operator-controller-manager created
$ kubectl -n 'awx' get pods
NAME                                              READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-8b7dfcb58-k7jt8   2/2     Running   0          10m

$ cat <<EOF > 'awx.yaml'
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
EOF
$ yq -iy '.resources+=["awx.yaml"]' 'kustomization.yaml'
$ kubectl apply -k '.'  # this failed because awx has no ARM images yet

$ # Fine. I'll do it myself.
$ git clone 'https://github.com/ansible/awx.git'
$ cd 'awx'
$ make awx-kube-build
…
ERROR: failed to solve: process "/bin/sh -c make sdist && /var/lib/awx/venv/awx/bin/pip install dist/awx.tar.gz" did not complete successfully: exit code: 2
make: *** [awx-kube-build] Error 1
$ # (ノಠ益ಠ)ノ彡┻━┻
```

</details>

## Further readings

- [Website]
- [Kubernetes]
- [Minikube]

### Sources

- [AWX's documentation]
- [AWX's repository]
- [Operator's documentation]
- [Operator's repository]
- [Basic install]
- [arm64 image pulled shows amd64 as its arch]

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
[basic install]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/installation/basic-install.html
[operator's documentation]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/
[operator's repository]: https://github.com/ansible/awx-operator/
[website]: https://www.ansible.com/awx/

<!-- Others -->
[arm64 image pulled shows amd64 as its arch]: https://github.com/brancz/kube-rbac-proxy/issues/79#issuecomment-826557647
