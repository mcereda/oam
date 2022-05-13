# Kubectl

## TL;DR

```shell
# Shot the merged configuration.
kubectl config view

# Get specific values from the configuration.
kubectl config view -o jsonpath='{.users[].name}'
kubectl config view -o jsonpath='{.users[*].name}'
kubectl config view -o jsonpath='{.users[?(@.name == "e2e")].user.password}'

# Set config values.
kubectl config set-context --current --namespace=keda
kubectl config set-context gce --user=cluster-admin --namespace=foo
kubectl config set-credentials \
  kubeuser/foo.kubernetes.com --username=kubeuser --password=kubepassword

# Delete config values.
kubectl config unset users.foo

# Use multiple config files at once.
# This will merge them in one big temporary config file.
KUBECONFIG="path/to/kube/config1:path/to/kube/configN"

# List contexts.
kubectl config get-contexts
kubectl config current-context

# Set context as the default one.
kubectl config use-context docker-desktop
kubectl config use-context gce

# List and filter resources.
kubectl get pods
kubectl get pods -n kube-system coredns-845757d86-47np2
kubectl get namespaces,pods --show-labels
kubectl get deployment nginx -o yaml
kubectl get services -A -o wide
kubectl get replicasets --sort-by=.metadata.name
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'
kubectl get pv --sort-by=.spec.capacity.storage
kubectl get configmap myconfig -o jsonpath='{.data.ca\.crt}'
kubectl get node -L='!node-role.kubernetes.io/master'
kubectl get pods --field-selector=status.phase=Running
kubectl get pods --selector=app=cassandra -o \
  jsonpath='{.items[*].metadata.labels.version}'

# List all pods in status 'Shutdown'.
kubectl get pods -A \
  -0 jsonpath='{.items[?(@.status.reason=="Shutdown")].metadata.name}'

# Show detailed information about resources.
kubectl describe node pi
kubectl describe pods redis-0,redis-1

# Start a Pod.
kubectl run nginx --image nginx
kubectl run --rm -i --tty -n keda busybox --image=busybox -- sh

# Start a Pod and write its specs into a file.
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml

# Create a single instance deployment of 'nginx'.
kubectl create deployment nginx --image=nginx

# Start a Job using an existing Job as template
kubectl create job backup-before-upgrade-13.6.2-to-13.9.2 \
  --from=cronjob.batch/backup -n gitlab

# Wait for a pod to be 'ready'.
kubectl wait --for 'condition=ready' \
  pod -L 'app.kubernetes.io/component=controller' --timeout 120s

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
kubectl logs \
  $(kubectl get pods | grep $ID | head -n 1 | awk -F ' ' '{print $1}')

# Sort events by timestamp.
kubectl get events --sort-by .metadata.creationTimestamp

# Show the documentation for Pods' manifests.
kubectl explain pods

# Create resources from manifests.
kubectl apply -f ./manifest.yaml
kubectl apply -f ./m1.yaml -f ./m2.yaml
kubectl apply -f ./dir
kubectl apply -f https://git.io/vPieo
cat <<-EOF | kubectl apply -f -
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
EOF
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

# Verify user's permissions on the cluster.
kubectl auth can-i create roles

# Taint a Node.
kubectl taint nodes node1 key1=value1:NoSchedule

# Taint all nodes in a certain nodepool (Azure AKS).
kubectl get nodes \
  -l "agentpool=nodepool1" \
  -o jsonpath='{.items[*].metadata.name}'
| xargs -n1 -I{} -p kubectl taint nodes {} key1=value1:NoSchedule

# Remove a taint.
# Notice the '-' sign at the end.
kubectl taint nodes node1 key1=value1:NoSchedule-

# If a taint with that key and effect already exists, replace its value.
kubectl taint nodes foo dedicated=special-user:NoSchedule

# Mark Nodes as unschedulable.
kubectl cordon my-node

# Mark my-node as schedulable.
kubectl uncordon my-node

# Drain my-node in preparation for maintenance.
kubectl drain my-node

# Show metrics for a given node.
kubectl top node my-node

# Display addresses of the master and services.
kubectl cluster-info

# Dump the complete current cluster state.
kubectl cluster-info dump
kubectl cluster-info dump --output-directory=/path/to/cluster-state

# Listen on port 5000 on the local machine and forward connections to port 6000
# of my-pod
kubectl port-forward my-pod 5000:6000

# List supported resources types along with their short name, API group, Kind,
# and whether they are namespaced.
kubectl api-resources
kubectl api-resources --namespaced=true
kubectl api-resources -o name
kubectl api-resources -o wide
kubectl api-resources --verbs=list,get

# Delete non-default service accounts.
kubectl delete serviceaccounts \
  $(kubectl get serviceaccounts -o jsonpath="{.items[?(@.metadata.name!='default')].metadata.name}" \
    | tr ' ' ',')

# Show the ExternalIO value for all nodes.
kubectl get nodes \
  -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'

# List ready nodes.
JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
  && kubectl get nodes -o jsonpath="$JSONPATH" | grep "Ready=True"

# List all images excluding "k8s.gcr.io/coredns:1.6.2"
kubectl get pods -A -o=custom-columns='DATA:spec.containers[?(@.image!="k8s.gcr.io/coredns:1.6.2")].image'

# List all the images running in a cluster.
kubectl get pods -A -o=custom-columns='DATA:spec.containers[*].image'

# List all fields under '.metadata' regardless of their name.
kubectl get pods -A -o=custom-columns='DATA:metadata.*'

# List all secrets currently in use by a Pod.
kubectl get pods -o json \
 | jq '.items[].spec.containers[].env[]?.valueFrom.secretKeyRef.name' \
 | grep -v null | sort | uniq

# List the name of Pods belonging to a particular RC.
SELECTOR=${$(kubectl get rc my-rc --output=json | jq -j '.spec.selector | to_entries | .[] | "\(.key)=\(.value),"')%?}
kubectl get pods --selector=$SELECTOR --output=jsonpath='{.items..metadata.name}'

# List the containerID of initContainers from all Pods.
# Helpful when cleaning up stopped containers while avoiding the removal of
# initContainers
kubectl get pods --all-namespaces \
  -o jsonpath='{range .items[*].status.initContainerStatuses[*]}{.containerID}{"\n"}{end}' \
 | cut -d/ -f3

# Produce a period-delimited tree of all keys returned for nodes.
# Helpful when trying to locate a specific key within a complex nested JSON
# structure.
kubectl get nodes -o json | jq -c 'path(..)|[.[]|tostring]|join(".")'

# Produce a period-delimited tree of all keys returned for Pods, etc
kubectl get pods -o json | jq -c 'path(..)|[.[]|tostring]|join(".")'

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
cat pod.json | kubectl replace -f -

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

# Add Labels to resources.
kubectl label pods nginx custom-name=awesome

# Add Aannotations.
kubectl annotate pods alpine icon-url=http://goo.gl/XXBTWq

# Autoscale resources.
kubectl autoscale deployment foo --min=2 --max=10

# Partially update resources.
kubectl patch node k8s-node-1 -p '{"spec":{"unschedulable":true}}'

# Update a container's image.
# 'spec.containers[*].name' is required because it's a merge key.
kubectl patch pod valid-pod -p '{"spec":{"containers":[{"name":"kubernetes-serve-hostname","image":"new image"}]}}'

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
kubectl get pods --no-headers=true \
 | awk '/pattern1|pattern2/{print $1}' \
 | xargs  kubectl delete pods

# Enable shell completion.
source <(kubectl completion bash)
echo "[[ $commands[kubectl] ]] && source <(kubectl completion zsh)" >> ~/.zshrc
```

## Configuration

`kubectl` looks for a file named `config` in the `$HOME/.kube` directory by default. One can specify other kubeconfig files by setting the `KUBECONFIG` environment variable or using the `--kubeconfig` flag:

```shell
KUBECONFIG="config.local:~/.kube/config" kubectl config view
kubectl config --kubeconfig config.local view
```

The configuration file can be edited, or acted upon from the command line:

```shell
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

## Further readings

- [Assigning Pods to Nodes]
- [Taints and Tolerations]
- [Commands reference]
- [Configure access to multiple clusters]

## Sources

- [Cheatsheet]
- [Run a single-instance stateful application]
- [Run a replicated stateful application]
- [Accessing an application on Kubernetes in Docker]

<!-- docs -->
[assigning pods to nodes]: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
[cheatsheet]: https://kubernetes.io/docs/reference/kubectl/cheatsheet
[commands reference]: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
[configure access to multiple clusters]: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/
[taints and tolerations]: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/

<!-- other articles -->
[accessing an application on kubernetes in docker]: https://medium.com/@lizrice/accessing-an-application-on-kubernetes-in-docker-1054d46b64b1
[run a replicated stateful application]: https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/
[run a single-instance stateful application]: https://kubernetes.io/docs/tasks/run-application/run-single-instance-stateful-application/
