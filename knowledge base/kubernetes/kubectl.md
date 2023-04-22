# Kubectl <!-- omit in toc -->

Command line tool for communicating with a Kubernetes cluster's control plane using the Kubernetes API.

Resource types are case **in**sensitive and can be specified in their singular, plural or abbreviated form for convenience:

```sh
# The two commands below are equivalent.
kubectl get deployment,replicasets,pods -A
kubectl get deploy,rs,po -A
```

Use `kubectl api-resources` to check out the available resources and their abbreviations.

Multiple resources types can be specified together, but only one resource name is accepted at a time.<br/>
Resource names are case sensitive and will filter the requested resources; use the `-l`, `--selector` option to get around filtering:

```sh
kubectl get deployments,replicasets -A
kubectl get pod etcd-minikube -n kube-system
kubectl get pods -l app=nginx,tier=frontend
```

### Table of contents

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
   1. [Configure access to multiple clusters](#configure-access-to-multiple-clusters)
1. [Create resources](#create-resources)
1. [Output formatting](#output-formatting)
1. [Verbosity and debugging](#verbosity-and-debugging)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Enable shell completion.
source <(kubectl completion 'bash')
echo "[[ $commands[kubectl] ]] && source <(kubectl completion 'zsh')" >> ~/.zshrc

# Shot the merged configuration.
kubectl config view

# Get specific values from the configuration.
kubectl config view -o jsonpath='{.users[].name}'
kubectl config view -o jsonpath='{.users[*].name}'
kubectl config view -o jsonpath='{.users[?(@.name == "e2e")].user.password}'

# Set configuration values.
kubectl config set-context --current --namespace='keda'
kubectl config set-context 'gce' --user='cluster-admin' --namespace='foo'
kubectl config set-credentials \
  'kubeuser/foo.kubernetes.com' --username='kubeuser' --password='kubepassword'

# Delete configuration values.
kubectl config unset 'users.foo'

# Use multiple config files at once.
# This will temporarily merge them in one big configuration file.
KUBECONFIG="path/to/config1:path/to/configN"

# List contexts.
kubectl config get-contexts
kubectl config current-context

# Set context as the default one.
kubectl config use-context 'docker-desktop'
kubectl config use-context 'gce'

# Display addresses of the master and services.
kubectl cluster-info

# Dump the complete current cluster state.
kubectl cluster-info dump
kubectl cluster-info dump --output-directory='/path/to/cluster-state'

# List supported resources types along with their short name, API group, Kind,
# and whether they are namespaced.
kubectl api-resources
kubectl api-resources --namespaced='true'
kubectl api-resources -o 'name'
kubectl api-resources -o 'wide'
kubectl api-resources --verbs='list,get'

# Show the documentation about resources or their fields.
kubectl explain 'pods'
kubectl explain 'pods.spec.containers'

# List and filter resources.
kubectl get pods
kubectl get 'pod/coredns-845757d86-47np2' -n 'kube-system'
kubectl get namespaces,pods --show-labels
kubectl get services -A -o 'wide'
kubectl get rs --sort-by='.metadata.name'
kubectl get pv --sort-by='.spec.capacity.storage' --no-headers
kubectl get po --sort-by='.status.containerStatuses[0].restartCount'
kubectl get events --sort-by '.metadata.creationTimestamp'
kubectl get pods --field-selector='status.phase=Running'
kubectl get node -l='!node-role.kubernetes.io/master'
kubectl get replicasets -l 'environment in (prod, qa)'
kubectl get deploy --selector 'tier,tier notin (frontend)'

# Extract information from resources' definition.
kubectl get deployment 'nginx' -o 'yaml'
kubectl get cm 'kube-root-ca.crt' -o jsonpath='{.data.ca\.crt}'
kubectl get po -o=jsonpath='{.items..metadata.name}'
kubectl get po -l 'app=redis' -o jsonpath='{.items[*].metadata.labels.version}'
kubectl get nodes \
  -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'

# List all fields under '.metadata' regardless of their name.
kubectl get pods -A -o=custom-columns='DATA:metadata.*'

# List images being run in a cluster.
kubectl get po -A -o=custom-columns='DATA:spec.containers[*].image'
kubectl get po -A -o=custom-columns='DATA:spec.containers[?(@.image!="k8s.gcr.io/coredns:1.6.2")].image'

# List all pods in status 'Shutdown'.
kubectl get po -A \
  -o jsonpath='{.items[?(@.status.reason=="Shutdown")].metadata.name}'

# List ready nodes.
kubectl get nodes \
  -o jsonpath='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
| grep "Ready=True"

# List all secrets currently in use by a Pod.
kubectl get pods -o 'json' \
| jq '.items[].spec.containers[].env[]?.valueFrom.secretKeyRef.name' \
| grep -v 'null' | sort | uniq

# List the name of Pods belonging to a particular RC.
SELECTOR=${$(kubectl get rc my-rc --output=json | jq -j '.spec.selector | to_entries | .[] | "\(.key)=\(.value),"')%?} kubectl get pods -l=$SELECTOR \
  -o=jsonpath='{.items..metadata.name}'

# List the containerID of initContainers from all Pods.
# Helpful when cleaning up stopped containers while avoiding the removal of
# initContainers
kubectl get pods --all-namespaces \
  -o jsonpath='{range .items[*].status.initContainerStatuses[*]}{.containerID}{"\n"}{end}' \
| cut -d/ -f3

# Produce a period-delimited tree of all keys returned for nodes.
# Helpful when trying to locate a specific key within a complex nested JSON
# structure.
kubectl get nodes -o 'json' | jq -c 'path(..)|[.[]|tostring]|join(".")'

# Show detailed information about resources.
kubectl describe node pi
kubectl describe deploy,rs,po -l 'app=redis'

# Create resources from manifests.
kubectl apply -f 'manifest.yaml'
kubectl apply -f 'path/to/m1.yaml' -f './m2.yaml'
kubectl apply -f 'dir/'
kubectl apply -f 'https://git.io/vPieo'
cat <<-EOF | kubectl apply -f -
  apiVersion: v1
  kind: Secret
  metadata:
    name: mysecret
  type: Opaque
  data:
    password: $(echo -n "s33msi4" | base64 -w0)
    username: $(echo -n "jane" | base64 -w0)
EOF

# Compare the current state of the cluster against the state it would be in if
# a manifest was applied
kubectl diff -f ./manifest.yaml

# Start a Pod.
kubectl run 'nginx' --image 'nginx'
kubectl run 'busybox' --rm -it --image='busybox' -n 'keda' -- sh
kubectl run 'alpine' --restart=Never -it --image 'alpine' -- sh
kubectl run 'ephemeral' --image=registry.k8s.io/pause:3.1 --restart=Never

# Start a Pod and write its specs into a file.
kubectl run 'nginx' --image='nginx' --dry-run='client' -o 'yaml' > 'pod.yaml'

# Create a single instance deployment of 'nginx'.
kubectl create deployment 'nginx' --image 'nginx'

# Start a Job printing "Hello World".
kubectl create job 'hello' --image 'busybox:1.28' -- echo "Hello World"

# Start a Job using an existing Job as template.
kubectl create job 'backup-before-upgrade-13.6.2-to-13.9.2' \
  --from=cronjob.batch/backup -n 'gitlab'

# Start a CronJob printing "Hello World" every minute.
kubectl create cronjob 'hello' --image=busybox:1.28 --schedule="*/1 * * * *" \
  -- echo "Hello World"

# Wait for a pod to be 'ready'.
kubectl wait --for 'condition=ready' --timeout 120s \
  pod -l 'app.kubernetes.io/component=controller'

# Update the 'image' field of the 'www' containers from the 'frontend'
# Deployment.
# This starts a rolling update.
kubectl set image deployment/frontend www=image:v2

# Show the history of resources, including the revision.
kubectl rollout history deployment/frontend

# Rollback resources to the latest previous version.
kubectl rollout undo deployment/frontend

# Rollback resources to a specific revision.
kubectl rollout undo deployment/frontend --to-revision=2

# Follow the rolling update status of the 'frontend' Deployment until its
# completion.
kubectl rollout status -w deployment/frontend

# Start a rolling restart of the 'frontend' Deployment.
kubectl rollout restart deployment/frontend

# Replace a Pod based on the JSON passed into stdin.
cat 'pod.json' | kubectl replace -f -

# Force replacement, deletion and recreation (in this order) of resources.
# This Will cause a service outage.
kubectl replace --force -f ./pod.json

# Create a service for a replicated 'nginx'.
# Set it to serve on port 80 and connect to the containers on port 8000.
kubectl expose rc nginx --port=80 --target-port=8000

# Update a single-container Pod's image tag.
kubectl get pod mypod -o yaml \
| sed 's/\(image: myimage\):.*$/\1:v4/' \
| kubectl replace -f -

# Add Labels.
kubectl label pods 'nginx' 'custom-name=awesome'
kubectl label ns 'default' 'pod-security.kubernetes.io/enforce=privileged'

# Add Annotations.
kubectl annotate pods alpine icon-url=http://goo.gl/XXBTWq

# Autoscale resources.
kubectl autoscale deployment foo --min=2 --max=10

# Partially update resources.
kubectl patch node k8s-node-1 -p '{"spec":{"unschedulable":true}}'

# Update a container's image.
# 'spec.containers[*].name' is required to specify the path of the merged key.
kubectl patch pod valid-pod \
  -p '{"spec":{"containers": [{"name": "kubernetes-serve-hostname","image":"new image"}]}}'

# Update a container's image using a JSONPatch with positional arrays.
kubectl patch pod valid-pod --type='json' \
  -p='[{"op": "replace", "path": "/spec/containers/0/image", "value":"new image"}]'

# Disable a Deployment's livenessProbe using a JSONPatch with positional arrays.
kubectl patch deployment valid-deployment --type json \
  -p='[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe"}]'

# Add a new element to a positional array.
kubectl patch sa default --type='json' \
  -p='[{"op": "add", "path": "/secrets/1", "value": {"name": "whatever" } }]'

# Edit the service named docker-registry.
kubectl edit svc/docker-registry
KUBE_EDITOR="nano" kubectl edit svc/docker-registry

# Scale a replicaset named 'foo' to 3
kubectl scale --replicas=3 rs/foo

# Scale a resource specified in "foo.yaml" to 3 replicas.
kubectl scale --replicas=3 -f foo.yaml

# If the Deployment named 'mysql''s current size is 2, scale it to 3.
kubectl scale --current-replicas=2 --replicas=3 deployment/mysql

# Scale multiple ReplicationControllers at once.
kubectl scale --replicas=5 rc/foo rc/bar rc/baz

# Delete a Pod using the type and name specified in pod.json.
kubectl delete -f ./pod.json

# Delete Pods and Services named 'baz' and 'foo'.
kubectl delete pod,service baz foo

# Delete pods and services with Label name=myLabel.
kubectl delete pods,services -l name=myLabel

# Delete all pods and services in namespace my-ns.
kubectl -n my-ns delete pod,svc --all

# Delete all pods matching awk's pattern1 or pattern2.
kubectl get pods --no-headers \
| awk '/pattern1|pattern2/{print $1}' \
| xargs -n1 kubectl delete pods

# Delete non-default service accounts.
kubectl get serviceaccounts \
  -o jsonpath="{.items[?(@.metadata.name!='default')].metadata.name}" \
| xargs -n1 kubectl delete serviceaccounts

# Attach to a running container.
kubectl attach my-pod -i

# Run command in existing Pods.
kubectl exec my-pod -- ls /
kubectl exec my-pod -c my-container -- ls /

# Show metrics for a given Pod and its containers.
kubectl top pod busybox --containers

# Get logs from resources.
kubectl logs redis-0
kubectl logs -l name=myLabel
kubectl logs my-pod -c my-container

# Follow logs.
kubectl logs -f my-pod
kubectl logs -f my-pod -c my-container
kubectl logs -f -l name=myLabel --all-containers

# Get logs for a previous instantiation of a container.
kubectl logs nginx --previous

# Get the logs of the first Pod matching ID.
kubectl logs $(kubectl get pods --no-headers | grep $ID | awk '{print $2}')

# Verify user's permissions on the cluster.
kubectl auth can-i create roles
kubectl auth can-i list pods

# Taint a Node.
kubectl taint nodes node1 key1=value1:NoSchedule

# Taint all nodes in a certain nodepool (Azure AKS).
kubectl get no -l "agentpool=nodepool1" -o jsonpath='{.items[*].metadata.name}'
| xargs -n1 -I{} -p kubectl taint nodes {} key1=value1:NoSchedule

# Remove a taint.
# Notice the '-' sign at the end.
kubectl taint nodes node1 key1=value1:NoSchedule-

# If a taint with that key and effect already exists, replace its value.
kubectl taint nodes foo dedicated=special-user:NoSchedule

# Execute a privileged, debug container.
kubectl debug -it 'node/docker-desktop' --image 'busybox:1.28'

# Mark Nodes as unschedulable.
kubectl cordon my-node

# Mark my-node as schedulable.
kubectl uncordon my-node

# Drain my-node in preparation for maintenance.
kubectl drain my-node

# Show metrics for a given node.
kubectl top node my-node

# Listen on port 5000 on the local machine and forward connections to port 6000
# of my-pod
kubectl port-forward my-pod 5000:6000

# Show Containers' status, properties and capabilities from the inside.
# Run the command from *inside* the container.
cat /proc/1/status

# Check a container's capabilities.
# Run the command from *inside* the container.
grep 'Cap' /proc/1/status
```

## Configuration

The configuration files are loaded as follows:

1. If the `--kubeconfig` flag is set, then only that file is loaded; the flag may only be set **once**, and no merging takes place:

   ```sh
   kubectl config --kubeconfig config.local view
   ```

2. If the `$KUBECONFIG` environment variable is set, then it is used as a list of paths following the normal path delimiting rules for your system; the files are merged:

   ```sh
   export KUBECONFIG="/tmp/config.local:.kube/config.prod"
   ```

   When a value is modified, it is modified in the file that defines the stanza; when a value is created, it is created in the first existing file; if no file in the chain exist, then the last file in the list is created with the configuration.

3. If none of the above happens, `~/.kube/config` is used, and no merging takes place.

The configuration file can be edited, or acted upon from the command line:

```sh
# Show the merged configuration.
kubectl config view
KUBECONFIG="~/.kube/config:config.local" kubectl config view

# Show specific values only.
kubectl config view -o jsonpath='{.users[].name}'
kubectl config view -o jsonpath='{.users[?(@.name == "e2e")].user.password}'

# Add a new user that supports basic auth.
kubectl config set-credentials kubeuser/foo.kubernetes.com \
  --username=kubeuser --password=kubepassword

# Delete user 'foo'.
kubectl config unset users.foo

# List the available contexts.
kubectl config get-contexts

# Display the current default context name.
kubectl config current-context

# Set the default context.
kubectl config use-context minikube

# Permanently setup specific contexts.
kubectl config set-context --current --namespace=ggckad-s2
kubectl config set-context gce --user=cluster-admin --namespace=foo
```

### Configure access to multiple clusters

See [configure access to multiple clusters] for details.

## Create resources

The preferred way to create resources is to define them inside `manifest`s and then apply those:

```yaml
---
# file manifest.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: busybox-sleep
spec:
  containers:
    - name: busybox
      image: busybox
      args:
        - sleep
        - "1000000"
---
apiVersion: v1
kind: Pod
metadata:
  name: busybox-sleep-less
spec:
  containers:
    - name: busybox
      image: busybox
      args:
        - sleep
        - "1000"
```

```sh
# Apply the manifest.
kubectl apply -f manifest.yaml

# Apply multiple manifests together.
kubectl apply -f path/to/m1.yaml -f m2.yaml

# Apply all manifests in a directory.
kubectl apply -f ./dir

# Apply a remote manifest.
kubectl apply -f https://git.io/vPieo

# Define a manifest using HEREDOC and apply it.
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  password: $(echo -n "s33msi4" | base64 -w0)
  username: $(echo -n "jane" | base64 -w0)
EOF
```

When subsequentially (re-)applying manifests, one can compare the current state of the cluster against the state it would be in if the manifest was applied:

```sh
kubectl diff -f manifest.yaml
```

Resources can also be created using default values or specifying them on the command line:

```sh
# Start a Pod.
kubectl run nginx --image nginx
kubectl run busybox --rm -it --image=busybox -n keda -- sh

# Start a Pod and write its specs into a file.
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml

# Create a single instance deployment of 'nginx'.
kubectl create deployment nginx --image=nginx

# Start a Job using an existing Job as template
kubectl create job backup-before-upgrade-13.6.2-to-13.9.2 \
  --from=cronjob.batch/backup -n gitlab
```

## Output formatting

Add the `-o`, `--output` option to a command:

Format                              | Description
----------------------------------- | -----------
`-o=custom-columns=<spec>`          | Print a table using a comma separated list of custom columns
`-o=custom-columns-file=<filename>` | Print a table using the custom columns template in the \<filename> file
`-o=json`                           | Output a JSON formatted API object
`-o=jsonpath=<template>`            | Print the fields defined in a jsonpath expression
`-o=jsonpath-file=<filename>`       | Print the fields defined by the jsonpath expression in the \<filename> file
`-o=name`                           | Print only the resource name and nothing else
`-o=wide`                           | Output in the plain-text format with any additional information, and for pods, the node name is included
`-o=yaml`                           | Output a YAML formatted API object

Examples using `-o=custom-columns`:

```sh
# Print all the container images running in the cluster.
kubectl get pods -A -o=custom-columns='DATA:spec.containers[*].image'

# As above, but exclude 'k8s.gcr.io/coredns:1.6.2' from the list.
kubectl get pods -A \
  -o=custom-columns='DATA:spec.containers[?(@.image!="k8s.gcr.io/coredns:1.6.2")].image'

# Print all fields under 'metadata' regardless of their name
kubectl get pods -A -o=custom-columns='DATA:metadata.*'
```

## Verbosity and debugging

Verbosity is controlled through the `-v` flag, or `--v` followed by an integer representing the log level.

General Kubernetes logging conventions and the associated log levels are described in the following table:

Verbosity | Description
--------- | -----------
`--v=0`   | Generally useful for this to always be visible to a cluster operator.
`--v=1`   | A reasonable default log level if you don't want verbosity.
`--v=2`   | Useful steady state information about the service and important log messages that may correlate to significant changes in the system. This is the recommended default log level for most systems.
`--v=3`   | Extended information about changes.
`--v=4`   | Debug level verbosity.
`--v=6`   | Display requested resources.
`--v=7`   | Display HTTP request headers.
`--v=8`   | Display HTTP request contents.
`--v=9`   | Display HTTP request contents without truncation of contents.


## Further readings

- [Assigning Pods to Nodes]
- [Taints and Tolerations]
- [Commands reference]
- [Configure access to multiple clusters]
- [Configure a Security Context for a Pod or Container]
- [Enforce Pod Security Standards with Namespace Labels]

## Sources

- [Cheatsheet]
- [Run a single-instance stateful application]
- [Run a replicated stateful application]
- [Accessing an application on Kubernetes in Docker]

<!-- project's references -->
[assigning pods to nodes]: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
[cheatsheet]: https://kubernetes.io/docs/reference/kubectl/cheatsheet
[commands reference]: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
[configure a security context for a pod or container]: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
[configure access to multiple clusters]: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
[enforce pod security standards with namespace labels]: https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/
[taints and tolerations]: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/

<!-- external references articles -->
[accessing an application on kubernetes in docker]: https://medium.com/@lizrice/accessing-an-application-on-kubernetes-in-docker-1054d46b64b1
[run a replicated stateful application]: https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/
[run a single-instance stateful application]: https://kubernetes.io/docs/tasks/run-application/run-single-instance-stateful-application/
