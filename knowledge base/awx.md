# Ansible AWX

1. [Deployment](#deployment)
1. [Removal](#removal)
1. [Testing](#testing)
   1. [Create a demo instance](#create-a-demo-instance)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Deployment

> ### Incomplete ARM64 image collection
>
> Consider using only AMD64 nodes to host the containers for AWX.
>
> As of 2024-04-11, AWX does **not** appear to provide ARM64 images for all its containers.<br/>
> One'll need to build their own missing ARM64 images and specify those during deployment. Good luck with that!

Starting from version 18.0, the [AWX Operator][operator's documentation] is the preferred way to install AWX.<br/>
It is meant to provide a Kubernetes-native installation method for AWX via an AWX Custom Resource Definition (CRD).

The operator will use an Ansible role to create all the AWX resources under its hood.<br/>
See [Iterating on the installer without deploying the operator].

<details>
  <summary>Using <code>kustomize</code></summary>

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
  <summary>Using <code>helm</code></summary>

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

Once the operator is installed, AWX instances can be created by leveraging the `AWX` CRD.<br/>
The basic definition for a quick testing instance is as follows:

```yaml
---
# file: 'awx-demo.yaml'
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
spec:
  no_log: false
  service_type: nodeport
  node_selector: |
    kubernetes.io/arch: amd64
```

Due to the operator being the one creating its resources, one's control is limited to what one can define in the AWX
resource's `spec` key.<br/>
See the [installer role's defaults] and any page under the _Advanced configuration_ section in the
[operator's documentation] for details.

Useful specs:

| Spec               | Description                                               | Reason                                                 |
| ------------------ | --------------------------------------------------------- | ------------------------------------------------------ |
| `no_log: false`    | See resource creation tasks' output in the operators'logs | Debug                                                  |
| `node_selector: …` | Select nodes to run on                                    | Use only specific nodes (see warning at the beginning) |

<details>
  <summary>Using <code>kubectl</code></summary>

```sh
$ cd '/tmp/awx'
/tmp/awx$ kubectl apply -f 'awx-demo.yaml'
```

</details>

<details>
  <summary>Using <code>kustomize</code></summary>

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

</details><br/>

The default user is `admin`.<br/>
Get the password from the `{instance}-admin-password` secret:

```sh
$ kubectl -n 'awx' get secret 'awx-demo-admin-password' -o jsonpath="{.data.password}" | base64 --decode
L2ZUgNTwtswVW3gtficG1Hd443l3Kicq
```

Connection:

```sh
kubectl -n 'awx' port-forward 'service/awx-service' '8080:http'
open 'http://localhost:8080'
```

## Removal

Remove the `AWX` resource associated to the instance to delete it:

```sh
$ kubectl delete awx 'awx-demo'
awx.awx.ansible.com "awx-demo" deleted
```

Remove the operator if not needed anymore:

```sh
# Using `kustomize`.
kubectl delete -k '/tmp/awx'

# Using `helm`.
helm -n 'awx' uninstall 'my-awx-operator'
```

Eventually, remove the namespace too to clean all things up:

```sh
kubectl delete ns 'awx'
```

## Testing

### Create a demo instance

<details>
  <summary>Run: follow the basic installation guide</summary>

[Guide][basic install]

  <details style="margin-left: 1em">
    <summary>
      1. ARM, Mac OS X, <code>minikube</code>, <code>kustomize</code>: failed: ARM images for AWX not available
    </summary>

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
awx-operator-controller-manager-8b7dfcb58-k7jt8   2/2     Running   0          3m42s

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
  <details style="margin-left: 1em">
    <summary>2. AMD64, OpenSUSE Leap 15.5, <code>minikube</code>, <code>kustomize</code></summary>

```sh
$ minikube start --cpus=4 --memory=6g --addons=ingress
😄  minikube v1.29.0 on Opensuse-Leap 15.5
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
NAME                                               READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-75b667b745-hjfc7   2/2     Running   0          3m43s

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
serviceaccount/awx-operator-controller-manager unchanged
…
deployment.apps/awx-operator-controller-manager unchanged
awx.awx.ansible.com/awx-demo created
$ minikube kubectl -- -n 'awx' get podsminikube kubectl -- -n 'awx' get pods
NAME                                               READY   STATUS      RESTARTS   AGE
awx-demo-migration-24.1.0-kqxcj                    0/1     Completed   0          9s
awx-demo-postgres-15-0                             1/1     Running     0          61s
awx-demo-task-7fcbb46c5d-ckf9d                     4/4     Running     0          48s
awx-demo-web-58668794c8-rfd7d                      3/3     Running     0          49s
awx-operator-controller-manager-75b667b745-hjfc7   2/2     Running     0          93s

$ # Default user is 'admin'.
$ minikube kubectl -- -n 'awx' get secret 'awx-demo-admin-password' -o jsonpath="{.data.password}" | base64 --decode
L2ZUgNTwtswVW3gtficG1Hd443l3Kicq
$ xdg-open $(minikube service -n 'awx' 'awx-demo-service' --url)

$ minikube kubectl -- delete -k '.'
```

  </details><br/>
</details>

<details>
  <summary>Run: follow the helm installation guide</summary>

[Guide][helm install on existing cluster]

  <details style="margin-left: 1em">
    <summary>1. AMD64, OpenSUSE Leap 15.5, <code>minikube</code>, <code>helm</code></summary>

```sh
$ minikube start --cpus=4 --memory=6g --addons=ingress
😄  minikube v1.29.0 on Opensuse-Leap 15.5
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
$ minikube kubectl -- -n 'awx' get pods
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
NAME                                              READY   STATUS      RESTARTS   AGE
awx-demo-migration-24.1.0-qhbq2                   0/1     Completed   0          12m
awx-demo-postgres-15-0                            1/1     Running     0          13m
awx-demo-task-87756dfbc-chx9t                     4/4     Running     0          12m
awx-demo-web-69d6d5d6c-wdxlv                      3/3     Running     0          12m
awx-operator-controller-manager-8b7dfcb58-k7jt8   2/2     Running     0          17m

$ # Default user is 'admin'.
$ minikube kubectl -- -n 'awx' get secret 'awx-demo-admin-password' -o jsonpath="{.data.password}" | base64 --decode
PoU9pFR2J5oFqymgX9I3I8swFgfZVkam
$ xdg-open $(minikube service -n 'awx' 'awx-demo-service' --url)

$ helm -n 'awx' uninstall 'my-awx-operator'
$ minikube kubectl -- delete ns 'awx'
```

  </details><br/>
</details>

<details>
  <summary>Run: kustomized helm chart</summary>

  <details style="margin-left: 1em">
    <summary>1. AMD64, OpenSUSE Leap 15.5, <code>minikube</code></summary>

<div class="warning" style="
  background-color: rgba(255,255,0,0.0625);
  border: solid yellow;  /* #FFFF00 */
  margin: 1em 0;
  padding: 1em 1em 0;
">
<header style="
  font-weight: bold;
  margin-bottom: 0.5em;
">Warning</header>

Mind including the CRDs from the helm chart.

</div>

```sh
$ minikube start --cpus=4 --memory=6g --addons=ingress
😄  minikube v1.29.0 on Opensuse-Leap 15.5
…
🌟  Enabled addons: storage-provisioner, default-storageclass, ingress
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

$ mkdir -p '/tmp/awx'
$ cd '/tmp/awx'

$ cat <<EOF > 'namespace.yaml'
---
apiVersion: v1
kind: Namespace
metadata:
  name: awx
EOF
$ cat <<EOF > 'kustomization.yaml'
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: awx
resources:
  - namespace.yaml
helmCharts:
  - name: awx-operator
    repo: https://ansible.github.io/awx-operator/
    version: 2.14.0
    releaseName: awx-operator
    includeCRDs: true
EOF
$ minikube kubectl -- apply -f <(minikube kubectl -- kustomize --enable-helm)
namespace/awx created
customresourcedefinition.apiextensions.k8s.io/awxbackups.awx.ansible.com created
…
deployment.apps/awx-operator-controller-manager created
$ minikube kubectl -- -n 'awx' get pods
NAME                                               READY   STATUS    RESTARTS   AGE
awx-operator-controller-manager-787d4945fb-fdffx   2/2     Running   0          3m36s

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
$ minikube kubectl -- apply -f <(minikube kubectl -- kustomize --enable-helm)
namespace/awx unchanged
…
deployment.apps/awx-operator-controller-manager unchanged
awx.awx.ansible.com/awx-demo created
$ minikube kubectl -- -n 'awx' get pods
NAME                                               READY   STATUS      RESTARTS   AGE
awx-demo-migration-24.1.0-zwv8w                    0/1     Completed   0          115s
awx-demo-postgres-15-0                             1/1     Running     0          10m
awx-demo-task-9c4655cb9-cmz87                      4/4     Running     0          8m3s
awx-demo-web-77f65cc65f-qhqrm                      3/3     Running     0          8m4s
awx-operator-controller-manager-787d4945fb-fdffx   2/2     Running     0          14m

$ # Default user is 'admin'.
$ minikube kubectl -- -n 'awx' get secret 'awx-demo-admin-password' -o jsonpath="{.data.password}" | base64 --decode
DgHIaA9onZj106osEmvECigzsBqutHqI
$ xdg-open $(minikube service -n 'awx' 'awx-demo-service' --url)

$ minikube kubectl -- delete -f <(minikube kubectl -- kustomize --enable-helm)
```

  </details>
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
- [Installer role's defaults]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[helm]: kubernetes/helm.md
[kubernetes]: kubernetes/README.md
[kustomize]: kubernetes/kustomize.md
[minikube]: kubernetes/minikube.md

<!-- Upstream -->
[awx's documentation]: https://ansible.readthedocs.io/projects/awx/en/latest/
[awx's repository]: https://github.com/ansible/awx/
[basic install]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/installation/basic-install.html
[helm install on existing cluster]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/installation/helm-install-on-existing-cluster.html
[installer role's defaults]: https://github.com/ansible/awx-operator/blob/ffba1b4712a0b03f1faedfa70e3a9ef0d443e4a6/roles/installer/defaults/main.yml
[iterating on the installer without deploying the operator]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/troubleshooting/debugging.html#iterating-on-the-installer-without-deploying-the-operator
[operator's documentation]: https://ansible.readthedocs.io/projects/awx-operator/en/latest/
[operator's repository]: https://github.com/ansible/awx-operator/
[website]: https://www.ansible.com/awx/

<!-- Others -->
[arm64 image pulled shows amd64 as its arch]: https://github.com/brancz/kube-rbac-proxy/issues/79#issuecomment-826557647
