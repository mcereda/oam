# Kubernetes

Open source container orchestration engine for containerized applications.<br />
Hosted by the [Cloud Native Computing Foundation][cncf].

1. [Concepts](#concepts)
   1. [Control plane](#control-plane)
      1. [API server](#api-server)
      1. [`kube-scheduler`](#kube-scheduler)
      1. [`kube-controller-manager`](#kube-controller-manager)
      1. [`cloud-controller-manager`](#cloud-controller-manager)
   1. [Worker Nodes](#worker-nodes)
      1. [`kubelet`](#kubelet)
      1. [`kube-proxy`](#kube-proxy)
      1. [Container runtime](#container-runtime)
      1. [Addons](#addons)
   1. [Workloads](#workloads)
      1. [Pods](#pods)
1. [Best practices](#best-practices)
1. [Volumes](#volumes)
   1. [hostPaths](#hostpaths)
   1. [emptyDirs](#emptydirs)
   1. [configMaps](#configmaps)
   1. [secrets](#secrets)
   1. [nfs](#nfs)
   1. [downwardAPI](#downwardapi)
   1. [PersistentVolumes](#persistentvolumes)
      1. [Resize PersistentVolumes](#resize-persistentvolumes)
1. [Authorization](#authorization)
   1. [RBAC](#rbac)
1. [Autoscaling](#autoscaling)
   1. [Pod scaling](#pod-scaling)
      1. [Horizontal Pod Autoscaler](#horizontal-pod-autoscaler)
      1. [Vertical Pod Autoscaler](#vertical-pod-autoscaler)
   1. [Node scaling](#node-scaling)
1. [Scheduling](#scheduling)
   1. [Dedicate Nodes to specific workloads](#dedicate-nodes-to-specific-workloads)
   1. [Spread Pods on Nodes](#spread-pods-on-nodes)
1. [Quality of service](#quality-of-service)
1. [Containers with high privileges](#containers-with-high-privileges)
   1. [Capabilities](#capabilities)
   1. [Privileged container vs privilege escalation](#privileged-container-vs-privilege-escalation)
1. [Sysctl settings](#sysctl-settings)
1. [Backup and restore](#backup-and-restore)
1. [Managed Kubernetes Services](#managed-kubernetes-services)
    1. [Best practices in cloud environments](#best-practices-in-cloud-environments)
1. [Edge computing](#edge-computing)
1. [Troubleshooting](#troubleshooting)
    1. [Golang applications have trouble performing as expected](#golang-applications-have-trouble-performing-as-expected)
    1. [Recreate Pods upon ConfigMap's or Secret's content change](#recreate-pods-upon-configmaps-or-secrets-content-change)
    1. [Run a command in a Pod right after its initialization](#run-a-command-in-a-pod-right-after-its-initialization)
    1. [Run a command just before a Pod stops](#run-a-command-just-before-a-pod-stops)
1. [Examples](#examples)
    1. [Create an admission webhook](#create-an-admission-webhook)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## Concepts

When using Kubernetes, one is using a cluster.

Kubernetes clusters consist of one or more hosts (_Nodes_) executing containerized applications.<br/>
In cloud environments, Nodes are also available in grouped sets (_Node Pools_) capable of automatic scaling.

Nodes host application workloads in the form of [_Pods_][pods].

The [_control plane_](#control-plane) manages the cluster's Nodes and Pods.

![Cluster components](components.svg)

### Control plane

Makes global decisions about the cluster (like scheduling).<br/>
Detects and responds to cluster events (like starting up a new Pod when a deployment has less replicas then it
requests).<br/>
Exposes the Kubernetes APIs and interfaces used to define, deploy, and manage the lifecycle of the cluster's
resources.

The control plane is composed by:

- The [API server](#api-server);
- The _distributed store_ for the cluster's configuration data.<br/>
  The current default store of choice is [`etcd`][etcd].
- The [scheduler](#kube-scheduler);
- The [cluster controller](#kube-controller-manager);
- The [cloud controller](#cloud-controller-manager).

Control plane components run on one or more cluster Nodes as Pods.<br/>
For ease of use, setup scripts typically start all control plane components on the **same** host and avoid **running**
other workloads on it.<br/>
In higher environments, the control plane usually runs across multiple **dedicated** Nodes in order to provide improved
fault-tolerance and high availability.

#### API server

Exposes the Kubernetes API. It is the front end for, and the core of, the Kubernetes control plane.<br/>
`kube-apiserver` is the main implementation of the Kubernetes API server, and is designed to scale horizontally (by
deploying more instances) and balance traffic between its instances.

The API server exposes the HTTP API that lets end users, different parts of a cluster and external components
communicate with one another, or query and manipulate the state of API objects in Kubernetes.<br/>
Can be accessed through command-line tools or directly using REST calls.<br/>
The serialized state of the objects is stored by writing them into `etcd`'s store.

Suggested the use of one of the available client libraries if writing an application using the Kubernetes API.<br/>
The complete API details are documented using OpenAPI.

Kubernetes supports multiple API versions, each at a different API path (e.g.: `/api/v1`,
`/apis/rbac.authorization.k8s.io/v1alpha1`).<br/>
All the different versions are representations of the same persisted data.<br/>
The server handles the conversion between API versions transparently.

Versioning is done at the API level, rather than at the resource or field level, to ensure the API presents a clear and
consistent view of system resources and behavior.<br/>
Also enables controlling access to end-of-life and/or experimental APIs.

API groups can be enabled or disabled.<br/>
API resources are distinguished by their **API group**, **resource type**, **namespace** (for namespaced resources), and
**name**.<br />
New API resources and new resource fields can be added often and frequently.<br/>
Elimination of resources or fields requires following the [API deprecation policy].

The Kubernetes API can be extended:

- using _custom resources_ to declaratively define how the API server should provide your chosen resource API, or
- extending the Kubernetes API by implementing an aggregation layer.

#### `kube-scheduler`

Detects newly created Pods with no assigned Node, and selects one for them to run on.

Scheduling decisions take into account:

- individual and collective resource requirements;
- hardware/software/policy constraints;
- Affinity and anti-Affinity specifications;
- data locality;
- inter-workload interference;
- deadlines.

#### `kube-controller-manager`

Runs _controller_ processes.<br />
Each controller is a separate process logically speaking; they are all compiled into a single binary and run in a single
process to reduce complexity.

Examples of these controllers are:

- the Node controller, which notices and responds when Nodes go down;
- the Replication controller, which maintains the correct number of Pods for every replication controller object in the
  system;
- the Job controller, which checks one-off tasks (_Job_) objects and creates Pods to run them to completion;
- the EndpointSlice controller, which populates _EndpointSlice_ objects providing a link between services and Pods;
- the ServiceAccount controller, which creates default ServiceAccounts for new Namespaces.

#### `cloud-controller-manager`

Embeds cloud-specific control logic, linking clusters to one's cloud provider's API and separating the components that
interact with that cloud platform from the components that only interact with clusters.

Clusters only run controllers that are specific to one's cloud provider.<br/>
If running Kubernetes on one's own premises, or in a learning environment inside one's own PC, the cluster will have no
cloud controller managers.

As with the `kube-controller-manager`, cloud controller managers combine several logically independent control loops
into single binaries run as single processes.<br/>
It can scale horizontally to improve performance or to help tolerate failures.

The following controllers can have cloud provider dependencies:

- the Node controller, which checks the cloud provider to determine if a Node has been deleted in the cloud after it
  stops responding;
- the route controller, which sets up routes in the underlying cloud infrastructure;
- the service controller, which creates, updates and deletes cloud provider load balancers.

### Worker Nodes

Each and every Node runs components providing a runtime environment for the cluster, and syncing with the control plane
to maintain workloads running as requested.

#### `kubelet`

A `kubelet` runs as an agent on each and every Node in the cluster, making sure that containers are run in a Pod.

It takes a set of _PodSpecs_ and ensures that the containers described in them are running and healthy.<br/>
It only manages containers created by Kubernetes.

#### `kube-proxy`

Network proxy running on each Node and implementing part of the Kubernetes Service concept.

It maintains all the network rules on Nodes which allow network communication to the Pods from network sessions inside
or outside of one's cluster.

It uses the operating system's packet filtering layer, if there is one and it's available; if not, it just forwards the
traffic itself.

#### Container runtime

The software responsible for running containers.

Kubernetes supports container runtimes like `containerd`, `CRI-O`, and any other implementation of the Kubernetes CRI
(Container Runtime Interface).

#### Addons

Addons use Kubernetes resources (_DaemonSet_, _Deployment_, etc) to implement cluster features.<br/>
As such, namespaced resources for addons belong within the `kube-system` namespace.

See [addons] for an extended list of the available addons.

### Workloads

Workloads consist of groups of containers ([_Pods_][pods]) and a specification for how to run them (_Manifest_).<br/>
Manifest files are written in YAML (preferred) or JSON format and are composed of:

- metadata,
- resource specifications, with attributes specific to the kind of resource they are describing, and
- status, automatically generated and edited by the control plane.

#### Pods

The smallest deployable unit of computing that one can create and manage in Kubernetes.<br/>
Pods contain one or more relatively tightly coupled application containers; they are always co-located (executed on the
same host) and co-scheduled (executed together), and **share** context, storage and network resources, and a
specification for how to run them.

Pods are (and _should be_) usually created trough other workload resources (like _Deployments_, _StatefulSets_, or
_Jobs_) and **not** directly.<br/>
Such parent resources leverage and manage _ReplicaSets_, which in turn manage copies of the same Pod. When deleted,
**all** the resources they manage are deleted with them.

Gotchas:

- If a Container specifies a memory or CPU `limit` but does **not** specify a memory or CPU `request`, Kubernetes
  automatically assigns it a resource `request` spec equal to the given `limit`.

## Best practices

Also see [configuration best practices] and the [production best practices checklist].

- Prefer an **updated** version of Kubernetes.<br/>
  The upstream project maintains release branches for the most recent three minor releases.<br/>
  Kubernetes 1.19 and newer receive approximately 1 year of patch support. Kubernetes 1.18 and older received
  approximately 9 months of patch support.
- Prefer **stable** versions of Kubernetes for production clusters.
- Prefer using **multiple Nodes** for production clusters.
- Prefer **consistent** versions of Kubernetes components throughout **all** Nodes.<br/>
  Components support [version skew][version skew policy] up to a point, with specific tools placing additional
  restrictions.
- Consider keeping **separation of ownership and control** and/or group related resources.<br/>
  Leverage [Namespaces].
- Consider **organizing** cluster and workload resources.<br/>
  Leverage [Labels][labels and selectors]; see [recommended Labels].
- Consider forwarding logs to a central log management system for better storage and easier access.
- Avoid sending traffic to Pods which are not ready to manage it.<br/>
  [Readiness probes][Configure Liveness, Readiness and Startup Probes] signal services to not forward requests until the
  probe verifies its own Pod is up.<br/>
  [Liveness probes][configure liveness, readiness and startup probes] ping the Pod for a response and check its health;
  if the check fails, they kill the current Pod and launch a new one.
- Avoid workloads and Nodes fail due limited resources being available.<br/>
  Set [resource requests and limits][resource management for pods and containers] to reserve a minimum amount of
  resources for Pods and limit their hogging abilities.
- Prefer smaller container images.
- Prioritize critical workloads.<br/>
  Leverage [quality of service](#quality-of-service).
- Instrument workloads to detect and respond to the `SIGTERM` signal to allow them to safely and cleanly shutdown.
- Avoid using bare Pods.<br/>
  Prefer defining them as part of a replica-based resource, like Deployments, StatefulSets, ReplicaSets or DaemonSets.
- Leverage [autoscalers](#autoscaling).
- Try to avoid workload disruption.<br/>
  Leverage Pod disruption budgets.
- Try to use all available Nodes.<br/>
  Leverage affinities, taint and tolerations.
- Push for automation.<br/>
  [GitOps].
- Apply the principle of least privilege.<br/>
  Reduce container privileges where possible.<br/>
  Leverage Role-based access control (RBAC).
- Restrict traffic between objects in the cluster.<br/>
  See [network policies].
- Continuously audit events and logs regularly, also for control plane components.
- Keep an eye on connection tables.<br/>
  Specially valid when using [connection tracking].
- Protect the cluster's ingress points.<br/>
  Firewalls, web application firewalls, application gateways.

## Volumes

Refer [volumes].

Sources to mount directories from.

They go by the `volumes` key in Pods' `spec`.<br/>
E.g., in a Deployment they are declared in its `spec.template.spec.volumes`:

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      volumes:
        - <volume source 1>
        - <volume source N>
```

Mount volumes in containers by using the `volumesMount`:

```yaml
apiVersion: apps/v1
kind: Pod
spec:
  containers:
    - name: some-container
      volumeMounts:
        - name: my-volume-source
          mountPath: /path/to/mount
          readOnly: false
          subPath: dir/in/volume
```

### hostPaths

Mount files or directories from the host Node's filesystem into Pods.

**Not** something most Pods will need, but powerful escape hatches for some applications.

Use cases:

- Containers needing access to Node-level system components<br/>
  E.g., containers transferring system logs to a central location and needing access to those logs using a read-only
  mount of `/var/log`.
- Making configuration files stored on the host system available read-only to _static_ Pods.
  This because static Pods **cannot** access ConfigMaps.

If mounted files or directories on the host are only accessible to `root`:

- Either the process needs to run as `root` in a privileged container,
- Or the files' permissions on the host need to be changed to allow the process to read from (or write to) the volume.

```yaml
apiVersion: apps/v1
kind: Pod
volumes:
  - name: example-volume
    # Mount '/data/foo' only if that directory already exists
    hostPath:
      path: /data/foo  # location on host
      type: Directory  # optional
```

### emptyDirs

Scrape disks for **temporary** Pod data.

**Not** shared between Pods.<br/>
All data is **destroyed** once the Pod is removed, but stays intact when Pods restart.

Use cases:

- Provide directories to create pid/lock or other special files for 3rd-party software when it's inconvenient or
  impossible to disable them.<br/>
  E.g., Java Hazelcast creates lockfiles in the user's home directory and there's no way to disable this behaviour.
- Store intermediate calculations which can be lost<br/>
  E.g., external sorting, buffering of big responses to save memory.
- Improve startup time after application crashes if the application in question pre-computes something before or during
  startup.</br>
  E.g., compressed assets in the application's image, decompressing data into temporary directory.

```yaml
apiVersion: apps/v1
kind: Pod
volumes:
  - name: my-empty-dir
    emptyDir:
      # Omit the 'medium' field to use disk storage.
      # The 'Memory' medium will create tmpfs to store data.
      medium: Memory
      sizeLimit: 1Gi
```

### configMaps

Inject configuration data into Pods.

When referencing a ConfigMap:

- Provide the name of the ConfigMap in the volume.
- Optionally customize the path to use for a specific entry in the ConfigMap.

```yaml
apiVersion: apps/v1
kind: Pod
spec:
  containers:
    - name: test
      volumeMounts:
        - name: config-vol
          mountPath: /etc/config
  volumes:
    - name: config-vol
      configMap:
        name: log-config
        items:
          - key: log_level
            path: log_level
    - name: my-configmap-volume
      configMap:
        name: my-configmap
        defaultMode: 0644  # posix access mode, set it to the most restricted value
        optional: true     # allow pods to start with this configmap missing, resulting in an empty directory
```

ConfigMaps **must** be created before they can be mounted.

One ConfigMap can be mounted into any number of Pods.

ConfigMaps are always mounted `readOnly`.

Containers using ConfigMaps as `subPath` volume mounts will **not** receive ConfigMap updates.

Text data is exposed as files using the UTF-8 character encoding.<br/>
Use `binaryData` For any other character encoding.

### secrets

Used to pass sensitive information to Pods.<br/>
E.g., passwords.

They behave like ConfigMaps but are backed by `tmpfs`, so they are never written to non-volatile storage.

Secrets **must** be created before they can be mounted.

Secrets are always mounted `readOnly`.

Containers using Secrets as `subPath` volume mounts will **not** receive Secret updates.

```yaml
apiVersion: apps/v1
kind: Pod
spec:
  volumes:
    - name: my-secret-volume
      secret:
        secretName: my-secret
        defaultMode: 0644
        optional: false
```

### nfs

mount **existing** NFS shares into Pods.

The contents of NFS volumes are preserved after Pods are removed and the volume is merely unmounted.<br/>
This means that NFS volumes can be pre-populated with data, and that data can be shared between Pods.

NFS can be mounted by multiple writers simultaneously.

One **cannot** specify NFS mount options in a Pod spec.<br/>
Either set mount options server-side or use `/etc/nfsmount.conf`.<br/>
Alternatively, mount NFS volumes via PersistentVolumes as they do allow to set mount options.

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
    - image: registry.k8s.io/test-web-server
      name: test-container
      volumeMounts:
      - mountPath: /my-nfs-data
        name: test-volume
  volumes:
    - name: test-volume
      nfs:
        server: my-nfs-server.example.com
        path: /my-nfs-volume
        readOnly: true
```

### downwardAPI

Downward APIs expose Pods' and containers' resource declaration or status field values.<br/>
Refer [Expose Pod information to Containers through files].

Downward API volumes make downward API data available to applications as read-only files in plain text format.

Containers using the downward API as `subPath` volume mounts will **not** receive updates when field values change.

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    cluster: test-cluster1
    rack: rack-22
    zone: us-east-coast
spec:
  volumes:
    - name: my-downward-api-volume
      downwardAPI:
        defaultMode: 0644
        items:
        - path: labels
          fieldRef:
            fieldPath: metadata.labels

# Mounting this volume results in a file with contents similar to the following:
# ```plaintext
# cluster="test-cluster1"
# rack="rack-22"
# zone="us-east-coast"
# ```
```

### PersistentVolumes

#### Resize PersistentVolumes

1. Check the `StorageClass` is set with `allowVolumeExpansion: true`:

   ```sh
   kubectl get storageClass 'storage-class-name' -o jsonpath='{.allowVolumeExpansion}'
   ```

1. Edit the PersistentVolumeClaim's `spec.resources.requests.storage` field.<br/>
   This will take care of the underlying PersistentVolume's size automagically.

   ```sh
   kubectl edit persistentVolumeClaim 'my-pvc'
   ```

1. Verify the change by checking the PVC's `status.capacity` field:

   ```sh
   kubectl get pvc 'my-pvc' -o jsonpath='{.status}'
   ```

   Should one see the message

   > Waiting for user to (re-)start a pod to finish file system resize of volume on node

   under the `status.conditions` field, just wait some time.<br/>
   It should **not** be necessary to restart the Pods, and the capacity should change soon to the requested one.

Gotchas:

- It's possible to recreate StatefulSets **without** the need of killing the Pods it controls.<br/>
  Reapply the STS' declaration with a new PersistentVolume size, and start new Pods to resize the underlying filesystem.

  <details>
    <summary>If deploying the STS via Helm</summary>

  1. Change the size of the PersistentVolumeClaims used by the STS:

     ```sh
     kubectl edit persistentVolumeClaims 'my-pvc'
     ```

  1. Delete the STS **without killing its Pods**:

     ```sh
     kubectl delete statefulSets.apps 'my-sts' --cascade 'orphan'
     ```

  1. Redeploy the STS with the changed size.
     It will retake ownership of existing Pods.

  1. Delete the STS' Pods one-by-one.<br/>
     During Pod restart, the Kubelet will resize the filesystem to match new block device size.

     ```sh
     kubectl delete pod 'my-sts-pod'
     ```

  </details>
  <details>
    <summary>If managing the STS manually</summary>

  1. Change the size of the PersistentVolumeClaims used by the STS:

     ```sh
     kubectl edit persistentVolumeClaims 'my-pvc'
     ```

  1. Note down the names of PVs for specific PVCs and their sizes:

     ```sh
     kubectl get persistentVolume 'my-pv'
     ```

  1. Dump the STS to disk:

     ```sh
     kubectl get sts 'my-sts' -o yaml > 'my-sts.yaml'
     ```

  1. Remove any extra field (like `metadata.{selfLink,resourceVersion,creationTimestamp,generation,uid}` and `status`)
     and set the template's PVC size to the value you want.

  1. Delete the STS **without killing its Pods**:

     ```sh
     kubectl delete sts 'my-sts' --cascade 'orphan'
     ```

  1. Reapply the STS.<br/>
     It will retake ownership of existing Pods.

     ```sh
     kubectl apply -f 'my-sts.yaml'
     ```

  1. Delete the STS' Pods one-by-one.<br/>
     During Pod restart, the Kubelet will resize the filesystem to match new block device size.

     ```sh
     kubectl delete pod 'my-sts-pod'
     ```

  </details>

## Authorization

### RBAC

Refer [Using RBAC Authorization].

_Role_s and _ClusterRole_s contain rules, each representing a set of permissions.<br/>
Permissions are purely additive - there are no _deny_ rules.

Roles are constrained to the namespace they are defined into.<br/>
ClusterRoles are **non**-namespaced resources, and are meant for cluster-wide roles.

<details style='padding: 0 0 0 1rem'>
  <summary>Role definition example</summary>

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
  - apiGroups:
      - ""  # "" = core API group
    resources:
      - pods
    verbs:
      - get
      - list
      - watch
```

</details>

<details style='padding: 0 0 1rem 1rem'>
  <summary>ClusterRole definition example</summary>

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # no `namespace` as ClusterRoles are non-namespaced
  name: secret-reader
rules:
  - apiGroups:
      - ""  # "" = core API group
    resources:
      - secrets
    verbs:
      - get
      - list
      - watch
```

</details>

Roles are usually used to grant access to workloads in Pods.<br/>
ClusterRoles are usually used to grant access to cluster-scoped resources (Nodes), non-resource endpoints (`/healthz`),
and namespaced resources across all namespaces.

_RoleBinding_s grant the permissions defined in Roles or ClusterRoles to the _Subjects_ (Users, Groups, or Service
Accounts) they reference, only within the namespace they are defined.
_ClusterRoleBinding_s do the same, but cluster-wide.

Bindings require the roles and the Subjects they refer to already exist.

<details style='padding: 0 0 0 1rem'>
  <summary>RoleBinding definition example</summary>

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: User
    name: jane  # case sensitive
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-secrets
  namespace: development
subjects:
  - kind: User
    name: bob  # case sensitive
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

</details>

<details style='padding: 0 0 1rem 1rem'>
  <summary>ClusterRoleBinding definition example</summary>

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
  - kind: Group
    name: manager  # case sensitive
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

</details>

Roles, ClusterRoles, RoleBindings and ClusterRoleBindings must be given valid [path segment names].

Bindings are **immutable**. After creating a binding, one **cannot** change the Role or ClusterRole it refers to.<br/>
Trying to change a binding's `roleRef` causes a validation error. To change it, one needs to remove the binding and
replace it whole.

Use the `kubectl auth reconcile` utility to create or update a manifest file containing RBAC objects.<br/>
It also handles deleting and recreating binding objects, if required, to change the role they refer to.

Wildcards can be used in resources and verb entries, but is not advised as it could result in overly permissive access
being granted to sensitive resources.

ClusterRoles can be **aggregated** into a single combined ClusterRole.

<details style='padding: 0 0 0 1rem'>

A controller watches for ClusterRole objects with `aggregationRule`s.

`aggregationRule`s define at least one label selector.<br/>
That selector will be used by the controller to match and combine other ClusterRoles into the rules field of the source
one.

New ClusterRoles matching the label selector of an existing aggregated ClusterRole will trigger adding the new rules
into the aggregated ClusterRole.

</details>

<details style='padding: 0 0 1rem 1rem'>
  <summary>Aggregated ClusterRole definition example</summary>

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-endpoints
  labels:
    rbac.example.com/aggregate-to-monitoring: "true"
rules:
  - apiGroups: [""]
    resources: ["services", "endpointslices", "pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring
aggregationRule:
  clusterRoleSelectors:
    - matchLabels:
        rbac.example.com/aggregate-to-monitoring: "true"
rules: []  # The control plane automatically fills in the rules
```

</details>

## Autoscaling

Controllers are available to scale Pods or Nodes automatically, both in number or size.

Automatic scaling of Pods is done in number by the Horizontal Pod Autoscaler, and in size by the
Vertical Pod Autoscaler.<br/>
Automatic scaling of Nodes is done in number by the Cluster Autoscaler, and in size by add-ons like [Karpenter].

> Be aware of mix-and-matching autoscalers for the same kind of resource.<br/>
> One can easily defy the work done by the other and make that resource behave unexpectedly.

K8S only comes with the Horizontal Pod Autoscaler by default.<br/>
Managed K8S usually also comes with the [Cluster Autoscaler] if autoscaling is enabled on the cluster resource.

The Horizontal and Vertical Pod Autoscalers require to access metrics.<br/>
This requires the [metrics server] addon to be installed and accessible.

### Pod scaling

Autoscaling of Pods by number requires the use of the [Horizontal Pod Autoscaler].<br/>
Autoscaling of Pods by size requires the use of the [Vertical Pod Autoscaler].

> Avoid running both the HPA **and** the VPA on the same workload.<br/>
> The two will easily collide and try to one-up each other, leading to the workload's Pods changing resources **and**
> number of replicas as frequently as they can.

Both HPA and VPA can currently monitor only CPU and Memory.<br/>
Use add-ons like [KEDA] to scale workloads based on different metrics.

#### Horizontal Pod Autoscaler

Refer [Horizontal Pod Autoscaling] and [HorizontalPodAutoscaler Walkthrough].<br/>
See also [HPA not scaling down].

The HPA decides on the amount of replicas on the premise of their **current** amount.<br/>
The algorithm's formula is `desiredReplicas = ceil[ currentReplicas * ( currentMetricValue / desiredMetricValue ) ]`.

Downscaling has a default cooldown period.

#### Vertical Pod Autoscaler

TODO

### Node scaling

Autoscaling of Nodes by number requires the [Cluster Autoscaler].

1. The Cluster Autoscaler routinely checks for pending Pods.
1. Pods fill up the available Nodes.
1. When Pods start to fail for lack of available resources, Nodes are added to the cluster.
1. When Pods are not failing due to lack of available resources and one or more Nodes are underused, the Autoscaler
   tries to fit the existing Pods in less Nodes.
1. If one or more Nodes can result unused from the previous step (DaemonSets are usually not taken into consideration),
   the Autoscaler will terminate them.

Autoscaling of Nodes by size requires add-ons like [Karpenter].

## Scheduling

When Pods are created, they go to a queue and wait to be scheduled.

The scheduler picks a Pod from the queue and tries to schedule it on a Node.<br/>
If no Node satisfies **all** the requirements of the Pod, preemption logic is triggered for that Pod.

Preemption logic tries to find a Node where the removal of one or more other _lower priority_ Pods would allow the
pending one to be scheduled on that Node.<br/>
If such a Node is found, one or more other lower priority Pods are evicted from that Node to make space for the pending
Pod. After the evicted Pods are gone, the pending Pod can be scheduled on that Node.

### Dedicate Nodes to specific workloads

Leverage [taints][Taints and Tolerations] and [Node Affinity][Affinity and anti-affinity].

Refer [Assigning Pods to Nodes].

1. Taint the dedicated Nodes:

   ```sh
   $ kubectl taint nodes 'host1' 'dedicated=devs:NoSchedule'
   node "host1" tainted
   ```

1. Add Labels to the same Nodes:

   ```sh
   $ kubectl label nodes 'host1' 'dedicated=devs'
   node "host1" labeled
   ```

1. Add matching tolerations and Node Affinity preferences to the dedicated workloads' Pod's `spec`:

   ```yaml
   spec:
     affinity:
       nodeAffinity:
         requiredDuringSchedulingIgnoredDuringExecution:
           nodeSelectorTerms:
             - matchExpressions:
               - key: dedicated
                 operator: In
                 values:
                 - devs
     tolerations:
       - key: "dedicated"
         operator: "Equal"
         value: "devs"
         effect: "NoSchedule"
   ```

### Spread Pods on Nodes

Leverage [Pod Topology Spread Constraints] and/or [Pod anti-affinity][Affinity and anti-affinity].

See also [Avoiding Kubernetes Pod Topology Spread Constraint Pitfalls].

<details>
  <summary>Basic examples<summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    example.org/app: someService
spec:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - podAffinityTerm:
            labelSelector:
              matchLabels:
                example.org/app: someService
            topologyKey: kubernetes.io/hostname
          weight: 100
  topologySpreadConstraints:
    - labelSelector:
        matchLabels:
          example.org/app: someService
      maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule
    - labelSelector:
        matchLabels:
          example.org/app: someService
      maxSkew: 1
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: ScheduleAnyway
```

## Quality of service

See [Configure Quality of Service for Pods] for more information.

QoS classes are used to make decisions about scheduling and evicting Pods.<br/>
When a Pod is created, it is also assigned one of the following QoS classes:

- _Guaranteed_, when **every** Container in the Pod, including init containers, has:

  - a memory limit **and** a memory request, **and** they are the same
  - a CPU limit **and** a CPU request, **and** they are the same

  ```yaml
  spec:
    containers:
      …
      resources:
        limits:
          cpu: 700m
          memory: 200Mi
        requests:
          cpu: 700m
          memory: 200Mi
      …
  status:
    qosClass: Guaranteed
  ```

- _Burstable_, when

  - the Pod does not meet the criteria for the _Guaranteed_ QoS class
  - **at least one** Container in the Pod has a memory **or** CPU request spec

  ```yaml
  spec:
    containers:
    - name: qos-demo
      …
      resources:
        limits:
          memory: 200Mi
        requests:
          memory: 100Mi
    …
  status:
    qosClass: Burstable
  ```

- _BestEffort_, when the Pod does not meet the criteria for the other QoS classes (its Containers have **no** memory or
  CPU limits **nor** requests)

  ```yaml
  spec:
    containers:
      …
      resources: {}
    …
  status:
    qosClass: BestEffort
  ```

## Containers with high privileges

Kubernetes [introduced a Security Context][security context design proposal] as a mitigation solution to some workloads
requiring to change one or more Node settings for performance, stability, or other issues (e.g. [ElasticSearch]).<br/>
This is usually achieved executing the needed command from an InitContainer with higher privileges than normal, which
will have access to the Node's resources and breaks the isolation Containers are usually famous for. If compromised, an
attacker can use this highly privileged container to gain access to the underlying Node.

From the design proposal:

> A security context is a set of constraints that are applied to a Container in order to achieve the following goals
> (from the [Security design][Security Design Proposal]):
>
> - ensure a **clear isolation** between the Container and the underlying host it runs on;
> - **limit** the ability of the Container to negatively impact the infrastructure or other Containers.
>
> \[The main idea is that] **Containers should only be granted the access they need to perform their work**. The
> Security Context takes advantage of containerization features such as the ability to
> [add or remove capabilities][Runtime privilege and Linux capabilities in Docker containers] to give a process some
> privileges, but not all the privileges of the `root` user.

### Capabilities

Adding capabilities to a Container is **not** making it _privileged_, **nor** allowing _privilege escalation_. It is
just giving the Container the ability to write to specific files or devices depending on the given capability.

This means having a capability assigned does **not** automatically make the Container able to wreak havoc on a Node, and
this practice **can be a legitimate use** of this feature instead.

From the feature's `man` page:

> Linux divides the privileges traditionally associated with superuser into distinct units, known as _capabilities_,
> which can be independently enabled and disabled. Capabilities are a per-thread attribute.

This also means a Container will be **limited** to its contents, plus the capabilities it has been assigned.

Some capabilities are assigned to all Containers by default, while others (the ones which could cause more issues)
require to be **explicitly** set using the Containers' `securityContext.capabilities.add` property.<br/>
If a Container is _privileged_ (see [Privileged container vs privilege escalation]), it will have access to **all** the
capabilities, with no regards of what are explicitly assigned to it.

Check:

- [Linux capabilities], to see what capabilities can be assigned to a process **in a Linux system**;
- [Runtime privilege and Linux capabilities in Docker containers] for the capabilities available **inside Kubernetes**,
  and
- [Container capabilities in Kubernetes] for a handy table associating capabilities in Kubernetes to their Linux
  variant.

### Privileged container vs privilege escalation

A _privileged container_ is very different from a _container leveraging privilege escalation_.

A **privileged container** does whatever a processes running directly on the Node can.<br/>
It will have automatically assigned **all** [capabilities](#capabilities), and being `root` in this container is
effectively being `root` on the Node it is running on.

> For a Container to be _privileged_, its definition **requires the `securityContext.privileged` property set to
> `true`**.

**Privilege escalation** allows **a process inside the Container** to gain more privileges than its parent process.<br/>
The process will be able to assume `root`-like powers, but will have access only to the **assigned**
[capabilities](#capabilities) and generally have limited to no access to the Node like any other Container.

> For a Container to _leverage privilege escalation_, its definition **requires the
> `securityContext.allowPrivilegeEscalation` property**:
>
> - to **either** be set to `true`, or
> - to **not be set** at all **if**:
>   - the Container is already privileged, or
>   - the Container has `SYS_ADMIN` capabilities.
>
> This property directly controls whether the [`no_new_privs`][No New Privileges Design Proposal] flag gets set on the
> Container's process.

From the [design document for `no_new_privs`][No New Privileges Design Proposal]:

> In Linux, the `execve` system call can grant more privileges to a newly-created process than its parent process.
> Considering security issues, since Linux kernel v3.5, there is a new flag named `no_new_privs` added to prevent those
> new privileges from being granted to the processes.
>
> `no_new_privs` is inherited across `fork`, `clone` and `execve` and **can not be unset**. With `no_new_privs` set,
> `execve` promises not to grant the privilege to do anything that could not have been done without the `execve` call.
>
> For more details about `no_new_privs`, please check the
> [Linux kernel documentation][no_new_privs linux kernel documentation].
>
> \[…]
>
> To recap, below is a table defining the default behavior at the pod security policy level and what can be set as a
> default with a pod security policy:
>
> | allowPrivilegeEscalation setting | uid = 0 or unset   | uid != 0           | privileged/CAP_SYS_ADMIN |
> | -------------------------------- | ------------------ | ------------------ | ------------------------ |
> | nil                              | no_new_privs=true  | no_new_privs=false | no_new_privs=false       |
> | false                            | no_new_privs=true  | no_new_privs=true  | no_new_privs=false       |
> | true                             | no_new_privs=false | no_new_privs=false | no_new_privs=false       |

## Sysctl settings

See [Using `sysctls` in a Kubernetes Cluster][using sysctls in a kubernetes cluster].

## Backup and restore

See [velero].

## Managed Kubernetes Services

Most cloud providers offer their managed versions of Kubernetes. Check their websites:

- [Azure Kubernetes Service]

### Best practices in cloud environments

All kubernetes clusters should:

- be created using **IaC** ([terraform], [pulumi]);
- have different Node Pools dedicated to different workloads;
- have at least one Node Pool composed by **non-preemptible** dedicated to critical services like Admission Controller
  Webhooks.

Each Node Pool should:

- have a _meaningful_ **name** (like `<prefix…>-<workload_type>-<random_id>`) to make it easy to recognize the workloads
  running on it or the features of the Nodes in it;
- have a _minimum_ set of _meaningful_ **labels**, like:
  - cloud provider information;
  - Node information and capabilities;
- sparse Nodes on multiple **availability zones**.

## Edge computing

If planning to run Kubernetes on a Raspberry Pi, see [k3s] and the
[Build your very own self-hosting platform with Raspberry Pi and Kubernetes] series of articles.

## Troubleshooting

### Golang applications have trouble performing as expected

Also see [Container CPU Requests & Limits Explained with GOMAXPROCS Tuning].

By default, Golang sets the `GOMAXPROCS` environment variable (the number of OS threads for Go code execution) **to the
number of available CPUs on the Node running the Pod**.<br/>
This is **different** from the amount of resources the Pod is allocated when a CPU limit is set in the Pod's
specification, and the Go scheduler might try to run more or less threads than the application has CPU time for.

Properly set the `GOMAXPROCS` environment variable in the Pod's specification to match the limits imposed to the
Pod.<br/>
If the CPU limit is less than `1000m` (1 CPU core), set `GOMAXPROCS=1`.

An easy way to do this is to reference the environment variable's value from other fields.<br/>
Refer [Expose Pod Information to Containers Through Environment Variables].

<details style='padding-left: 1rem'>

```yml
apiVersion: v1
kind: Pod
spec:
  containers:
    - env:
        - name: GOMAXPROCS
          valueFrom:
            resourceFieldRef:
              resource: limits.cpu
              divisor: "1"  # quantity resource core, canonicalizes value to X digits - '1': 2560m -> 3
      resources:
        limits:
          cpu: 2560m
```

</details>

### Recreate Pods upon ConfigMap's or Secret's content change

Use a checksum annotation to do the trick:

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    metadata:
      annotations:
        checksum/configmap: {{ include (print $.Template.BasePath "/configmap.yaml") $ | sha256sum }}
        checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") $ | sha256sum }}
        {{- if .podAnnotations }}
          {{- toYaml .podAnnotations | trim | nindent 8 }}
        {{- end }}
```

### Run a command in a Pod right after its initialization

Use a container's `lifecycle.postStart.exec.command` spec:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  template:
    …
    spec:
      containers:
        - name: my-container
          …
          lifecycle:
            postStart:
              exec:
                command: ["/bin/sh", "-c", "echo 'heeeeeeey yaaaaaa!'"]
```

### Run a command just before a Pod stops

Leverage the `preStop` hook instead of `postStart`.

> Hooks **are not passed parameters**, and this includes environment variables
> Use a script if you need them. See [container hooks] and [preStop hook doesn't work with env variables]

Since kubernetes version 1.9 and forth, volumeMounts behavior on secret, configMap, downwardAPI and projected have
changed to Read-Only by default.
A workaround to the problem is to create an `emptyDir` Volume and copy the contents into it and execute/write whatever
you need:

```yaml
  initContainers:
    - name: copy-ro-scripts
      image: busybox
      command: ['sh', '-c', 'cp /scripts/* /etc/pre-install/']
      volumeMounts:
        - name: scripts
          mountPath: /scripts
        - name: pre-install
          mountPath: /etc/pre-install
  volumes:
    - name: pre-install
      emptyDir: {}
    - name: scripts
      configMap:
        name: bla
```

## Examples

### Create an admission webhook

See the example's [README][create an admission webhook].

## Further readings

Usage:

- [Official documentation][documentation]
- [Configure a Pod to use a ConfigMap]
- [Distribute credentials securely using Secrets]
- [Configure a Security Context for a Pod or a Container]
  - [Set capabilities for a Container]
- [Using `sysctl`s in a Kubernetes Cluster][using sysctls in a kubernetes cluster]

Concepts:

- [Namespaces]
- [Container hooks]
- Kubernetes' [security context design proposal]
- Kubernetes' [No New Privileges Design Proposal]
- [Linux kernel documentation about `no_new_privs`][no_new_privs linux kernel documentation]
- [Linux capabilities]
- [Runtime privilege and Linux capabilities in Docker containers]
- [Container capabilities in Kubernetes]
- [Kubernetes SecurityContext Capabilities Explained]
- [Best practices for Pod security in Azure Kubernetes Service (AKS)]
- [Network policies]

Distributions:

- [K3S]
- [RKE2]
- [K0S]

Tools:

- [`kubectl`][kubectl]
- [`helm`][helm]
- [`helmfile`][helmfile]
- [`kustomize`][kustomize]
- [`kubeval`][kubeval]
- `kube-score`
- [`kubectx`+`kubens`][kubectx+kubens], alternative to [`kubie`][kubie] and [`kubeswitch`][kubeswitch]
- [`kubeswitch`][kubeswitch], alternative to [`kubie`][kubie] and [`kubectx`+`kubens`][kubectx+kubens]
- [`kube-ps1`][kube-ps1]
- [`kubie`][kubie], alternative to [`kubeswitch`][kubeswitch], and to [`kubectx`+`kubens`][kubectx+kubens] and
  [`kube-ps1`][kube-ps1]
- [Minikube]
- [Kubescape]

Add-ons of interest:

- [Certmanager][cert-manager]
- [ExternalDNS][external-dns]
- [Flux]
- [Istio]
- [KEDA]
- [k8s-ephemeral-storage-metrics]

Others:

- The [Build your very own self-hosting platform with Raspberry Pi and Kubernetes] series of articles
- [Why separate your Kubernetes workload with nodepool segregation and affinity options]
- [RBAC.dev]
- [Scaling Kubernetes to 7,500 nodes]

### Sources

- Kubernetes' [concepts]
- [How to run a command in a Pod after initialization]
- [Making sense of Taints and Tolerations]
- [Read-only filesystem error]
- [preStop hook doesn't work with env variables]
- [Configure Quality of Service for Pods]
- [Version skew policy]
- [Labels and Selectors]
- [Recommended Labels]
- [Configure Liveness, Readiness and Startup Probes]
- [Configuration best practices]
- [Cloudzero Kubernetes best practices]
- [Scaling K8S nodes without breaking the bank or your sanity - Brandon Wagner & Nick Tran, Amazon]
- [Kubernetes Troubleshooting - The Complete Guide]
- [Kubernetes cluster autoscaler]
- [Common labels]
- [What is Kubernetes?]
- [Using RBAC Authorization]
- [Expose Pod information to Containers through files]
- [Avoiding Kubernetes Pod Topology Spread Constraint Pitfalls]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[horizontal pod autoscaler]: #horizontal-pod-autoscaler
[vertical pod autoscaler]: #vertical-pod-autoscaler
[pods]: #pods
[privileged container vs privilege escalation]: #privileged-container-vs-privilege-escalation

<!-- Knowledge base -->
[azure kubernetes service]: ../cloud%20computing/azure/aks.md
[cert-manager]: cert-manager.md
[cluster autoscaler]: cluster%20autoscaler.md
[connection tracking]: ../connection%20tracking.placeholder
[create an admission webhook]: ../../examples/kubernetes/create%20an%20admission%20webhook/README.md
[etcd]: ../etcd.md
[external-dns]: external-dns.md
[flux]: flux.md
[gitops]: ../gitops.md
[helm]: helm.md
[helmfile]: helmfile.md
[istio]: istio.md
[k0s]: k0s.placeholder
[k3s]: k3s.md
[karpenter]: karpenter.md
[keda]: keda.md
[kubectl]: kubectl.md
[kubescape]: kubescape.md
[kubeval]: kubeval.md
[kustomize]: kustomize.md
[metrics server]: metrics%20server.md
[minikube]: minikube.md
[network policies]: network%20policies.md
[pulumi]: ../pulumi.md
[rke2]: rke2.md
[terraform]: ../terraform.md
[velero]: velero.md

<!-- Upstream -->
[addons]: https://kubernetes.io/docs/concepts/cluster-administration/addons/
[Affinity and anti-affinity]: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity
[api deprecation policy]: https://kubernetes.io/docs/reference/using-api/deprecation-policy/
[Assigning Pods to Nodes]: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
[common labels]: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
[concepts]: https://kubernetes.io/docs/concepts/
[configuration best practices]: https://kubernetes.io/docs/concepts/configuration/overview/
[configure a pod to use a configmap]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
[configure a security context for a pod or a container]: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
[configure liveness, readiness and startup probes]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
[configure quality of service for pods]: https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/
[container hooks]: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#container-hooks
[distribute credentials securely using secrets]: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
[documentation]: https://kubernetes.io/docs/home/
[Expose Pod Information to Containers Through Environment Variables]: https://kubernetes.io/docs/tasks/inject-data-application/environment-variable-expose-pod-information/
[expose pod information to containers through files]: https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/
[Horizontal Pod Autoscaling]: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
[HorizontalPodAutoscaler Walkthrough]: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
[labels and selectors]: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
[namespaces]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[no new privileges design proposal]: https://github.com/kubernetes/design-proposals-archive/blob/main/auth/no-new-privs.md
[path segment names]: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#path-segment-names
[Pod Topology Spread Constraints]: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/
[production best practices checklist]: https://learnk8s.io/production-best-practices
[recommended labels]: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
[resource management for pods and containers]: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
[security context design proposal]: https://github.com/kubernetes/design-proposals-archive/blob/main/auth/security_context.md
[security design proposal]: https://github.com/kubernetes/design-proposals-archive/blob/main/auth/security.md
[set capabilities for a container]: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container
[Taints and Tolerations]: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
[using rbac authorization]: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
[using sysctls in a kubernetes cluster]: https://kubernetes.io/docs/tasks/administer-cluster/sysctl-cluster/
[version skew policy]: https://kubernetes.io/releases/version-skew-policy/
[volumes]: https://kubernetes.io/docs/concepts/storage/volumes/

<!-- Others -->
[Avoiding Kubernetes Pod Topology Spread Constraint Pitfalls]: https://medium.com/wise-engineering/avoiding-kubernetes-pod-topology-spread-constraint-pitfalls-d369bb04689e
[best practices for pod security in azure kubernetes service (aks)]: https://learn.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security
[build your very own self-hosting platform with raspberry pi and kubernetes]: https://kauri.io/build-your-very-own-self-hosting-platform-with-raspberry-pi-and-kubernetes/5e1c3fdc1add0d0001dff534/c
[cloudzero kubernetes best practices]: https://www.cloudzero.com/blog/kubernetes-best-practices
[cncf]: https://www.cncf.io/
[container capabilities in kubernetes]: https://unofficial-kubernetes.readthedocs.io/en/latest/concepts/policy/container-capabilities/
[Container CPU Requests & Limits Explained with GOMAXPROCS Tuning]: https://victoriametrics.com/blog/kubernetes-cpu-go-gomaxprocs/
[elasticsearch]: https://github.com/elastic/helm-charts/issues/689
[how to run a command in a pod after initialization]: https://stackoverflow.com/questions/44140593/how-to-run-command-after-initialization/44146351#44146351
[HPA not scaling down]: https://stackoverflow.com/questions/65704583/hpa-not-scaling-down#65770916
[k8s-ephemeral-storage-metrics]: https://github.com/jmcgrath207/k8s-ephemeral-storage-metrics
[kube-ps1]: https://github.com/jonmosco/kube-ps1
[kubectx+kubens]: https://github.com/ahmetb/kubectx
[kubernetes cluster autoscaler]: https://www.kubecost.com/kubernetes-autoscaling/kubernetes-cluster-autoscaler/
[kubernetes securitycontext capabilities explained]: https://www.golinuxcloud.com/kubernetes-securitycontext-capabilities/
[kubernetes troubleshooting - the complete guide]: https://komodor.com/learn/kubernetes-troubleshooting-the-complete-guide/
[kubeswitch]: https://github.com/danielfoehrKn/kubeswitch
[kubie]: https://github.com/sbstp/kubie
[linux capabilities]: https://man7.org/linux/man-pages/man7/capabilities.7.html
[making sense of taints and tolerations]: https://medium.com/kubernetes-tutorials/making-sense-of-taints-and-tolerations-in-kubernetes-446e75010f4e
[no_new_privs linux kernel documentation]: https://www.kernel.org/doc/Documentation/prctl/no_new_privs.txt
[prestop hook doesn't work with env variables]: https://stackoverflow.com/questions/61929055/kubernetes-prestop-hook-doesnt-work-with-env-variables#62135231
[rbac.dev]: https://rbac.dev/
[read-only filesystem error]: https://stackoverflow.com/questions/49614034/kubernetes-deployment-read-only-filesystem-error/51478536#51478536
[runtime privilege and linux capabilities in docker containers]: https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
[scaling k8s nodes without breaking the bank or your sanity - brandon wagner & nick tran, amazon]: https://www.youtube.com/watch?v=UBb8wbfSc34
[scaling kubernetes to 7,500 nodes]: https://openai.com/index/scaling-kubernetes-to-7500-nodes/
[what is kubernetes?]: https://www.youtube.com/watch?v=a2gfpZE8vXY
[why separate your kubernetes workload with nodepool segregation and affinity options]: https://medium.com/contino-engineering/why-separate-your-kubernetes-workload-with-nodepool-segregation-and-affinity-rules-cb5225953788
