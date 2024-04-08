# Ansible AWX

1. [Installation](#installation)
1. [Uninstallation](#uninstallation)
1. [Testing](#testing)
   1. [Create a demo instance in minikube](#create-a-demo-instance-in-minikube)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

<!-- Uncomment if needed
## TL;DR
-->

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

The operator will use an Ansible role to create all the AWX resources under its hood.<br/>
See [Iterating on the installer without deploying the operator].

<details>
  <summary>Using kustomize</summary>

```sh
$ mkdir -p '/tmp/awx'
$ cd '/tmp/awx'

# Specify the tag to use.
/tmp/awx$ cat <<EOF > 'kustomization.yaml'
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: awx
resources:
  - github.com/ansible/awx-operator/config/default?ref=2.14.0
    # https://github.com/ansible/awx-operator/releases
EOF

# Start the operator.
/tmp/awx$ kubectl apply -k '.'
namespace/awx created
…
deployment.apps/awx-operator-controller-manager created
/tmp/awx$ kubectl -n 'awx' get pods
NAME                                              READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-8b7dfcb58-k7jt8   2/2     Running   0          10m
```

</details>

<details style="margin-bottom: 1em;">
  <summary>Using the helm chart</summary>

```sh
# Add the operator's repository.
$ helm repo add 'awx-operator' 'https://ansible.github.io/awx-operator/'
"awx-operator" has been added to your repositories
$ helm repo update 'awx-operator'
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "awx-operator" chart repository
Update Complete. ⎈Happy Helming!⎈

$ helm search repo 'awx-operator'
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
awx-operator/awx-operator       2.14.0          2.14.0          A Helm chart for the AWX Operator

# Install the operator.
$ helm -n 'awx' upgrade -i --create-namespace 'my-awx-operator' 'awx-operator/awx-operator' --version '2.14.0'
Release "my-awx-operator" does not exist. Installing it now.
NAME: my-awx-operator
LAST DEPLOYED: Mon Apr  8 15:34:00 2024
NAMESPACE: awx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWX Operator installed with Helm Chart version 2.14.0
$ kubectl -n 'awx' get pods
NAME                                               READY   STATUS      RESTARTS   AGE
awx-operator-controller-manager-75b667b745-g9g9c   2/2     Running     0          17m
```

</details>

The default user is 'admin'.<br/>
Get the password from the `{instance}-admin-password` secret:

```sh
$ kubectl -n 'awx' get secret 'awx-demo-admin-password' -o jsonpath="{.data.password}" | base64 --decode
L2ZUgNTwtswVW3gtficG1Hd443l3Kicq
```

Once the operator is installed, AWX instances can be created by leveraging the `awx` CRD.
The basic definition is as follows:

```yaml
---
# file: 'awx-demo.yaml'
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
```

Settings are configured through the `spec`key.<br/>
See any page under the Advanced configuration section in the [operator's documentation].

<details>
  <summary>Using kubectl</summary>

```sh
$ cd '/tmp/awx'
/tmp/awx$ kubectl apply -f 'awx-demo.yaml'
```

</details>

<details>
  <summary>Using kustomize</summary>

```sh
$ cd '/tmp/awx'

/tmp/awx$ yq -iy '.resources+=["awx-demo.yaml"]' 'kustomization.yaml'
/tmp/awx$ kubectl apply -k '.'
```

</details>

<details>
  <summary>Using the helm chart's integrated definition</summary>

```sh
# Update the operator by telling it to also deploy the AWX instance.
$ helm -n 'awx' upgrade -i --create-namespace 'my-awx-operator' 'awx-operator/awx-operator' --version '2.14.0' \
  --set 'AWX.enabled=true' --set 'AWX.name=awx-demo'
Release "my-awx-operator" has been upgraded. Happy Helming!
NAME: my-awx-operator
LAST DEPLOYED: Mon Apr  8 15:37:47 2024
NAMESPACE: awx
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
AWX Operator installed with Helm Chart version 2.14.0
$ kubectl -n 'awx' get pods
NAME                                               READY   STATUS      RESTARTS   AGE
awx-demo-migration-24.1.0-qhbq2                    0/1     Completed   0          12m
awx-demo-postgres-15-0                             1/1     Running     0          13m
awx-demo-task-87756dfbc-chx9t                      4/4     Running     0          12m
awx-demo-web-69d6d5d6c-wdxlv                       3/3     Running     0          12m
awx-operator-controller-manager-75b667b745-g9g9c   2/2     Running     0          17m
```

</details>

## Uninstallation

Remove the `awx` resource associated to the instance to remove AWX:

```sh
$ kubectl delete awx 'awx-demo'
awx.awx.ansible.com "awx-demo" deleted
```

Remove the operator:

```sh
# Using `kustomize`.
kubectl delete -k '/tmp/awx'

# Using `helm`.
helm -n 'awx' uninstall 'my-awx-operator'
```

Eventually, remove the namespace too:

```sh
kubectl delete ns 'awx'
```

## Testing

### Create a demo instance in [minikube]

<details>
  <summary>Run: follow the basic installation guide</summary>

[Guide][basic install]

  <details>
    <summary>1. ARM, Mac OS X, Kustomize: failed: ARM images for AWX not available</summary>

```sh
$ minikube start --cpus=4 --memory=6g --addons=ingress
…
🌟  Enabled addons: storage-provisioner, default-storageclass, ingress
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

$ mkdir -p '/tmp/awx'
$ cd '/tmp/awx'

$ # There was no ARM version of the 'kube-rbac-proxy' image upstream, so it was impossible to just use the `make deploy`
$ # command as explained in the basic install.
$ # Defaulting to use 'quay.io' as repository as the ARM version of that image is available there.
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
awx-operator-controller-manager-8b7dfcb58-k7jt8   2/2     Running   0          3m

$ cat <<EOF > 'awx-demo.yaml'
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
EOF
$ yq -iy '.resources+=["awx-demo.yaml"]' 'kustomization.yaml'
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

  <details>
    <summary>2. AMD64, OpenSUSE Leap, Kustomize</summary>

```sh
$ minikube start --cpus=4 --memory=6g --addons=ingress
…
🌟  Enabled addons: storage-provisioner, default-storageclass, ingress
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

$ mkdir -p '/tmp/awx'
$ cd '/tmp/awx'

$ # Simulating the need to use a custom repository for the sake of testing, so I cannot just use the `make deploy`
$ # command as explained in the basic install.
$ # In this case, the repository will be 'quay.io'.
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
EOF
$ minikube kubectl -- apply -k '.'
namespace/awx created
…
deployment.apps/awx-operator-controller-manager created
$ minikube kubectl -- -n 'awx' get pods
NAME                                              READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-8b7dfcb58-k7jt8   2/2     Running   0          10m

$ cat <<EOF > 'awx-demo.yaml'
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  service_type: nodeport
EOF
$ yq -iy '.resources+=["awx-demo.yaml"]' 'kustomization.yaml'
$ minikube kubectl -- apply -k '.'

$ # Default user is 'admin'.
$ minikube kubectl -- -n 'awx' get secret 'awx-demo-admin-password' -o jsonpath="{.data.password}" | base64 --decode
L2ZUgNTwtswVW3gtficG1Hd443l3Kicq
$ xdg-open $(minikube service -n 'awx' 'awx-demo-service' --url)

$ minikube kubectl -- delete -k '.'
```

  </details>
</details>

<details>
  <summary>Run: follow the helm installation guide</summary>

[Guide][helm install on existing cluster]

  <details>
    <summary>1. AMD64, OpenSUSE Leap, Helm</summary>

```sh
$ minikube start --cpus=4 --memory=6g --addons=ingress
…
🌟  Enabled addons: storage-provisioner, default-storageclass, ingress
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

$ helm repo add 'awx-operator' 'https://ansible.github.io/awx-operator/'
"awx-operator" has been added to your repositories
$ helm repo update 'awx-operator'
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "awx-operator" chart repository
Update Complete. ⎈Happy Helming!⎈

$ helm search repo 'awx-operator'
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
awx-operator/awx-operator       2.14.0          2.14.0          A Helm chart for the AWX Operator

$ helm -n 'awx' upgrade -i --create-namespace 'my-awx-operator' 'awx-operator/awx-operator' --version '2.14.0'
Release "my-awx-operator" does not exist. Installing it now.
NAME: my-awx-operator
LAST DEPLOYED: Mon Apr  8 15:34:00 2024
NAMESPACE: awx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWX Operator installed with Helm Chart version 2.14.0
$ kubectl -n 'awx' get pods
NAME                                              READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-8b7dfcb58-k7jt8   2/2     Running   0          3m

$ helm -n 'awx' upgrade -i --create-namespace 'my-awx-operator' 'awx-operator/awx-operator' --version '2.14.0' \
  --set 'AWX.enabled=true' --set 'AWX.name=awx-demo'
Release "my-awx-operator" has been upgraded. Happy Helming!
NAME: my-awx-operator
LAST DEPLOYED: Mon Apr  8 15:37:47 2024
NAMESPACE: awx
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
AWX Operator installed with Helm Chart version 2.14.0
$ minikube kubectl -- -n 'awx' get pods
NAME                                               READY   STATUS      RESTARTS   AGE
awx-demo-migration-24.1.0-qhbq2                    0/1     Completed   0          12m
awx-demo-postgres-15-0                             1/1     Running     0          13m
awx-demo-task-87756dfbc-chx9t                      4/4     Running     0          12m
awx-demo-web-69d6d5d6c-wdxlv                       3/3     Running     0          12m
awx-operator-controller-manager-75b667b745-g9g9c   2/2     Running     0          17m

$ helm -n 'awx' uninstall 'my-awx-operator'
$ minikube kubectl -- delete ns 'awx'
```

  </details>

</details>

<details>
  <summary>Run: kustomized helm chart</summary>

TODO

</details>

## Further readings

- [Website]
- [Kubernetes]
- [Minikube]
- [Kustomize]
- [Helm]

### Sources

- [AWX's documentation]
- [AWX's repository]
- The [Operator's documentation]
- The [Operator's repository]
- [Basic install]
- [arm64 image pulled shows amd64 as its arch]
- [Helm install on existing cluster]
- [Iterating on the installer without deploying the operator]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[helm]: kubernetes/helm.md
[kubernetes]: kubernetes/README.md
[kustomize]: kubernetes/kustomize.md
[minikube]: kubernetes/minikube.md

<!-- Files -->
<!-- Upstream -->
[awx's documentation]: https://ansible.readthedocs.io/projects/awx/en/latest/
[awx's repository]: https://github.com/ansible/awx/
[basic install]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/installation/basic-install.html
[helm install on existing cluster]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/installation/helm-install-on-existing-cluster.html
[iterating on the installer without deploying the operator]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/troubleshooting/debugging.html#iterating-on-the-installer-without-deploying-the-operator
[operator's documentation]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/
[operator's repository]: https://github.com/ansible/awx-operator/
[website]: https://www.ansible.com/awx/

<!-- Others -->
[arm64 image pulled shows amd64 as its arch]: https://github.com/brancz/kube-rbac-proxy/issues/79#issuecomment-826557647
