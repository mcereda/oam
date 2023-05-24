# Kubernetes

Open source container orchestration engine for containerized applications.<br />
Hosted by the [Cloud Native Computing Foundation][cncf].

## Table of content <!-- omit in toc -->

1. [Components overview](#components-overview)
1. [The control plane](#the-control-plane)
   1. [`kube-apiserver`](#kube-apiserver)
   1. [`etcd`](#etcd)
   1. [`kube-scheduler`](#kube-scheduler)
   1. [`kube-controller-manager`](#kube-controller-manager)
   1. [`cloud-controller-manager`](#cloud-controller-manager)
1. [The worker nodes](#the-worker-nodes)
   1. [`kubelet`](#kubelet)
   1. [`kube-proxy`](#kube-proxy)
   1. [Container runtime](#container-runtime)
   1. [Addons](#addons)
1. [The API](#the-api)
1. [Pods](#pods)
   1. [Gotchas](#gotchas)
   1. [Quality of service](#quality-of-service)
1. [Containers with high privileges](#containers-with-high-privileges)
   1. [Capabilities](#capabilities)
   1. [Privileged containers vs privilege escalation](#privileged-containers-vs-privilege-escalation)
1. [Sysctl settings](#sysctl-settings)
1. [Managed Kubernetes Services](#managed-kubernetes-services)
   1. [Best practices in cloud environments](#best-practices-in-cloud-environments)
1. [Edge computing](#edge-computing)
1. [Troubleshooting](#troubleshooting)
    1. [Dedicate Nodes to specific workloads](#dedicate-nodes-to-specific-workloads)
    1. [Recreate Pods upon ConfigMap's or Secret's content change](#recreate-pods-upon-configmaps-or-secrets-content-change)
    1. [Run a command in a Pod right after its initialization](#run-a-command-in-a-pod-right-after-its-initialization)
    1. [Run a command just before a Pod stops](#run-a-command-just-before-a-pod-stops)
1. [Examples](#examples)
    1. [Create an admission webhook](#create-an-admission-webhook)
    1. [Prometheus on Kubernetes using Helm](#prometheus-on-kubernetes-using-helm)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Components overview

Kubernetes clusters consist of:

- one or more worker hosts (_nodes_), executing containerized applications (_workloads_);<br/>
  in cloud environments, nodes are also available in grouped sets (_node pools_) capable of automatic scaling;
- the _control plane_, an orchestration layer spanning one or more nodes and exposing the API and interfaces to define, deploy, and manage the lifecycle of nodes and workloads in the cluster.

![Cluster components](components.svg)

Workloads consist of groups of containers (_pods_) and a specification for how to run them.<br/>
Pods execute one or more co-located and co-scheduled containers in an encapsulating environment with shared storage and network resources, and are the smallest deployable units of computing that one can create and manage in Kubernetes.

## The control plane

The control plane's components make global decisions about the cluster (like scheduling), and detect and respond to cluster events (like starting up a new pod when a deployment has less replicas then it requests).

Control plane components run on one or more cluster nodes. For simplicity, set up scripts typically start all control plane components on the same host, and avoid running users' workloads on it.

### `kube-apiserver`

The API server exposes the Kubernetes API. It is the front end for, and the core of, the Kubernetes control plane.<br/>
`kube-apiserver` is the main implementation of the Kubernetes API server, and is designed to scale horizontally (by deploying more instances) and balance traffic between its instances.

### `etcd`

`etcd` is a consistent and highly-available key-value store used as Kubernetes' backing store for all cluster data.<br/>
See its [website][etcd] for more information.

### `kube-scheduler`

Detects newly created pods with no assigned node, and selects one for them to run on.

Scheduling decisions take into account:

- individual and collective resource requirements;
- hardware/software/policy constraints;
- affinity and anti-affinity specifications;
- data locality;
- inter-workload interference;
- deadlines.

### `kube-controller-manager`

Runs _controller_ processes.<br />
Each controller is a separate process logically speaking; they are all compiled into a single binary and run in a single process to reduce complexity.

Examples of these controllers are:

- the node controller, which notices and responds when nodes go down;
- the replication controller, which maintains the correct number of pods for every replication controller object in the system;
- the job controller, which checks one-off tasks (_job_) objects and creates pods to run them to completion;
- the EndpointSlice controller, which populates _EndpointSlice_ objects providing a link between services and pods;
- the ServiceAccount controller, which creates default ServiceAccounts for new namespaces.

### `cloud-controller-manager`

Embeds cloud-specific control logic, linking clusters to one's cloud provider's API and separating the components that interact with that cloud platform from the components that only interact with clusters.

They only run controllers that are specific to one's cloud provider. If you are running Kubernetes on your own premises, or in a learning environment inside your own PC, your cluster will have no cloud controller managers.

As with the `kube-controller-manager`, it combines several logically independent control loops into a single binary that you run as a single process. It can scale horizontally to improve performance or to help tolerate failures.

The following controllers can have cloud provider dependencies:

- the node controller, which checks the cloud provider to determine if a node has been deleted in the cloud after it stops responding;
- the route controller, which sets up routes in the underlying cloud infrastructure;
- the service controller, which creates, updates and deletes cloud provider load balancers.

## The worker nodes

Each and every node runs components providing a runtime environment for the cluster, and syncing with the control plane to maintain workloads running as requested.

### `kubelet`

A `kubelet` runs as an agent on each and every node in the cluster, making sure that containers are run in a pod.

It takes a set of _PodSpecs_ and ensures that the containers described in them are running and healthy.<br/>
It only manages containers created by Kubernetes.

### `kube-proxy`

Network proxy running on each node and implementing part of the Kubernetes Service concept.

It maintains all the network rules on nodes which allow network communication to the Pods from network sessions inside or outside of your cluster.

It uses the operating system's packet filtering layer, if there is one and it's available; if not, it forwards the traffic itself.

### Container runtime

The software that is responsible for running containers.

Kubernetes supports container runtimes like `containerd`, `CRI-O`, and any other implementation of the Kubernetes CRI (Container Runtime Interface).

### Addons

Addons use Kubernetes resources (_DaemonSet_, _Deployment_, etc) to implement cluster features, and as such namespaced resources for addons belong within the `kube-system` namespace.

See [addons] for an extended list of the available addons.

## The API

The API server exposes an HTTP API that lets end users, different parts of your cluster, and external components communicate with one another. This lets you query and manipulate the state of API objects in Kubernetes and can be accessed through command-line tools or directly using REST calls. The serialized state of the objects is stored by writing them into `etcd`.

Consider using one of the client libraries if you are writing an application using the Kubernetes API. The complete API details are documented using OpenAPI.

Kubernetes supports multiple API versions, each at a different API path (like `/api/v1` or `/apis/rbac.authorization.k8s.io/v1alpha1`); the server handles the conversion between API versions transparently. Versioning is done at the API level rather than at the resource or field level; this ensures that the API presents a clear and consistent view of system resources and behavior, and enables controlling access to end-of-life and/or experimental APIs. All the different versions are representations of the same persisted data.

To make it easier to evolve and to extend them, Kubernetes implements API groups that can be enabled or disabled. API resources are distinguished by their **API group**, **resource type**, **namespace** (for namespaced resources), and **name**.<br />
New API resources and new resource fields can be added often and frequently. Elimination of resources or fields requires following the [API deprecation policy].

The Kubernetes API can be extended:

- using _Custom resources_ to declaratively define how the API server should provide your chosen resource API, or
- extending the Kubernetes API by implementing an aggregation layer.

## Pods

The smallest deployable unit of computing that one can create and manage in Kubernetes.<br/>
Pods contain one or more relatively tightly coupled application Containers; they are always co-located and co-scheduled, and share context, storage/network resources, and a specification for how to run them.

Pods are usually created trough workload resources (Deployments, StatefulSets or Jobs) and **not** directly.

### Gotchas

- If a Container specifies a memory or CPU `limit` but does **not** specify a memory or CPU `request`, Kubernetes automatically assigns it a resource `request` spec equal to the given `limit`.

### Quality of service

See [Configure Quality of Service for Pods] for more information.

QoS classes are used to make decisions about scheduling and evicting Pods.  
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

- _BestEffort_, when the Pod does not meet the criteria for the other QoS classes (its Containers have **no** memory or CPU limits **nor** requests)

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

Kubernetes [introduced a Security Context][security context design proposal] as a mitigation solution to some workloads requiring to change one or more Node settings for performance, stability, or other issues (e.g. [ElasticSearch]).<br/>
This is usually achieved executing the needed command from an InitContainer with higher privileges than normal, which will have access to the Node's resources and breaks the isolation Containers are usually famous for. If compromised, an attacker can use this highly privileged container to gain access to the underlying Node.

From the design proposal:

> A security context is a set of constraints that are applied to a Container in order to achieve the following goals (from the [Security design][Security Design Proposal]):
>
> - ensure a **clear isolation** between the Container and the underlying host it runs on;
> - **limit** the ability of the Container to negatively impact the infrastructure or other Containers.
>
> [The main idea is that] **Containers should only be granted the access they need to perform their work**. The Security Context takes advantage of containerization features such as the ability to [add or remove capabilities][Runtime privilege and Linux capabilities in Docker containers] to give a process some privileges, but not all the privileges of the `root` user.

### Capabilities

Adding capabilities to a Container is **not** making it _privileged_, **nor** allowing _privilege escalation_. It is just giving the Container the ability to write to specific files or devices depending on the given capability.

This means having a capability assigned does **not** automatically make the Container able to wreak havoc on a Node, and this practice **can be a legitimate use** of this feature instead.

From the feature's `man` page:

> Linux divides the privileges traditionally associated with superuser into distinct units, known as _capabilities_, which can be independently enabled and disabled. Capabilities are a per-thread attribute.

This also means a Container will be **limited** to its contents, plus the capabilities it has been assigned.

Some capabilities are assigned to all Containers by default, while others (the ones which could cause more issues) require to be **explicitly** set using the Containers' `securityContext.capabilities.add` property.<br/>
If a Container is _privileged_ (see [Privileged container vs privilege escalation](#privileged-container-vs-privilege-escalation)), it will have access to **all** the capabilities, with no regards of what are explicitly assigned to it.

Check:
- [Linux capabilities], to see what capabilities can be assigned to a process **in a Linux system**;
- [Runtime privilege and Linux capabilities in Docker containers] for the capabilities available **inside Kubernetes**, and
- [Container capabilities in Kubernetes] for a handy table associating capabilities in Kubernetes to their Linux variant.

### Privileged containers vs privilege escalation

A _privileged container_ is very different from a _container leveraging privilege escalation_.

A **privileged container** does whatever a processes running directly on the Node can.<br/>
It will have automatically assigned **all** [capabilities](#capabilities), and being `root` in this container is effectively being `root` on the Node it is running on.

> For a Container to be _privileged_, its definition **requires the `securityContext.privileged` property set to `true`**.

**Privilege escalation** allows **a process inside the Container** to gain more privileges than its parent process.<br/>
The process will be able to assume `root`-like powers, but will have access only to the **assigned** [capabilities](#capabilities) and generally have limited to no access to the Node like any other Container.

> For a Container to _leverage privilege escalation_, its definition **requires the `securityContext.allowPrivilegeEscalation` property**:
>
> - to **either** be set to `true`, or
> - to **not be set** at all **if**:
>   - the Container is already privileged, or
>   - the Container has `SYS_ADMIN` capabilities.
>
> This property directly controls whether the [`no_new_privs`][No New Privileges Design Proposal] flag gets set on the Container's process.

From the [design document for `no_new_privs`][No New Privileges Design Proposal]:

> In Linux, the `execve` system call can grant more privileges to a newly-created process than its parent process. Considering security issues, since Linux kernel v3.5, there is a new flag named `no_new_privs` added to prevent those new privileges from being granted to the processes.
>
> `no_new_privs` is inherited across `fork`, `clone` and `execve` and **can not be unset**. With `no_new_privs` set, `execve` promises not to grant the privilege to do anything that could not have been done without the `execve` call.
>
> For more details about `no_new_privs`, please check the [Linux kernel documentation][no_new_privs linux kernel documentation].
>
> […]
>
> To recap, below is a table defining the default behavior at the pod security policy level and what can be set as a default with a pod security policy:
>
> | allowPrivilegeEscalation setting | uid = 0 or unset   | uid != 0           | privileged/CAP_SYS_ADMIN |
> | -------------------------------- | ------------------ | ------------------ | ------------------------ |
> | nil                              | no_new_privs=true  | no_new_privs=false | no_new_privs=false       |
> | false                            | no_new_privs=true  | no_new_privs=true  | no_new_privs=false       |
> | true                             | no_new_privs=false | no_new_privs=false | no_new_privs=false       |

## Sysctl settings

See [Using `sysctls` in a Kubernetes Cluster][using sysctls in a kubernetes cluster].

## Managed Kubernetes Services

Most cloud providers offer their managed versions of Kubernetes. Check their websites:

- [Azure Kubernetes Service]

### Best practices in cloud environments

All kubernetes clusters should:

- be created using **IaC** ([terraform], [pulumi]);
- have different node pools dedicated to different workloads;
- have at least one node pool composed by **non-preemptible** dedicated to critical services like Admission Controller Webhooks.

Each node pool should:

- have a _meaningful_ **name** (like \<prefix..>-\<randomid>) to make it easy to recognize the workloads running on it or the features of the nodes in it;
- have a _minimum_ set of _meaningful_ **labels**, like:
  - cloud provider information;
  - node information and capabilities;
- sparse nodes on multiple **availability zones**.

## Edge computing

If planning to run Kubernetes on a Raspberry Pi, see [k3s] and the [Build your very own self-hosting platform with Raspberry Pi and Kubernetes] series of articles.

## Troubleshooting

### Dedicate Nodes to specific workloads

Leverage taints and node affinity:

1. Taint the Nodes:

   ```sh
   $ kubectl taint nodes 'host1' 'dedicated=devs:NoSchedule'
   node "host1" tainted
   ```

1. Add Labels to the nodes:

   ```sh
   $ kubectl label nodes 'host1' 'dedicated=devs'
   node "host1" labeled
   ```

1. add tolerations and node affinity to any Pod's `spec`:

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

Since kubernetes version 1.9 and forth, volumeMounts behavior on secret, configMap, downwardAPI and projected have changed to Read-Only by default.
A workaround to the problem is to create an `emtpyDir` Volume and copy the contents into it and execute/write whatever you need:

```sh
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

### Prometheus on Kubernetes using Helm

See the example's [README][prometheus on kubernetes using helm].

## Further readings

Usage:

- [Official documentation][documentation]
- [Configure a Pod to use a ConfigMap]
- [Distribute credentials securely using Secrets]
- [Configure a Security Context for a Pod or a Container]
  - [Set capabilities for a Container]
- [Using `sysctls` in a Kubernetes Cluster][Using sysctls in a Kubernetes Cluster]

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
- [Best practices for pod security in Azure Kubernetes Service (AKS)]

Tools:

- [`kubectl`][kubectl]
- [`helm`][helm]
- [`helmfile`][helmfile]
- [`kubeval`][kubeval]
- [`kubectx`+`kubens`][kubectx+kubens] (alternative to [`kubie`][kubie])
- [`kube-ps1`][kube-ps1]
- [`kubie`][kubie] (alternative to [`kubectx`+`kubens`][kubectx+kubens] and [`kube-ps1`][kube-ps1])
- [k3s]

Others:

- The [Build your very own self-hosting platform with Raspberry Pi and Kubernetes] series of articles
- [Why separate your Kubernetes workload with nodepool segregation and affinity options]

## Sources

All the references in the [further readings] section, plus the following:

- Kubernetes' [concepts]
- [How to run a command in a Pod after initialization]
- [Making sense of Taints and Tolerations]
- [Read-only filesystem error]
- [preStop hook doesn't work with env variables]
- [Configure Quality of Service for Pods]

<!-- project's documentation -->
[addons]: https://kubernetes.io/docs/concepts/cluster-administration/addons/
[api deprecation policy]: https://kubernetes.io/docs/reference/using-api/deprecation-policy/
[common labels]: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
[concepts]: https://kubernetes.io/docs/concepts/
[configure a pod to use a configmap]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
[configure a security context for a pod or a container]: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
[configure quality of service for pods]: https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/
[container hooks]: https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#container-hooks
[distribute credentials securely using secrets]: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
[documentation]: https://kubernetes.io/docs/home/
[namespaces]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[no new privileges design proposal]: https://github.com/kubernetes/design-proposals-archive/blob/main/auth/no-new-privs.md
[security context design proposal]: https://github.com/kubernetes/design-proposals-archive/blob/main/auth/security_context.md
[security design proposal]: https://github.com/kubernetes/design-proposals-archive/blob/main/auth/security.md
[set capabilities for a container]: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container
[using sysctls in a kubernetes cluster]: https://kubernetes.io/docs/tasks/administer-cluster/sysctl-cluster/

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
[azure kubernetes service]: ../azure/aks.md
[create an admission webhook]: ../../examples/kubernetes/create%20an%20admission%20webhook/README.md
[helm]: helm.md
[helmfile]: helmfile.md
[k3s]: k3s.md
[kubectl]: kubectl.md
[kubeval]: kubeval.md
[prometheus on kubernetes using helm]: ../../examples/kubernetes/prometheus%20on%20k8s%20using%20helm.md
[terraform]: ../terraform.md

<!-- external references -->

[best practices for pod security in azure kubernetes service (aks)]: https://learn.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security
[build your very own self-hosting platform with raspberry pi and kubernetes]: https://kauri.io/build-your-very-own-self-hosting-platform-with-raspberry-pi-and-kubernetes/5e1c3fdc1add0d0001dff534/c
[cncf]: https://www.cncf.io/
[container capabilities in kubernetes]: https://unofficial-kubernetes.readthedocs.io/en/latest/concepts/policy/container-capabilities/
[elasticsearch]: https://github.com/elastic/helm-charts/issues/689
[etcd]: https://etcd.io/docs/
[how to run a command in a pod after initialization]: https://stackoverflow.com/questions/44140593/how-to-run-command-after-initialization/44146351#44146351
[kubernetes securitycontext capabilities explained]: https://www.golinuxcloud.com/kubernetes-securitycontext-capabilities/
[linux capabilities]: https://man7.org/linux/man-pages/man7/capabilities.7.html
[making sense of taints and tolerations]: https://medium.com/kubernetes-tutorials/making-sense-of-taints-and-tolerations-in-kubernetes-446e75010f4e
[no_new_privs linux kernel documentation]: https://www.kernel.org/doc/Documentation/prctl/no_new_privs.txt
[prestop hook doesn't work with env variables]: https://stackoverflow.com/questions/61929055/kubernetes-prestop-hook-doesnt-work-with-env-variables#62135231
[read-only filesystem error]: https://stackoverflow.com/questions/49614034/kubernetes-deployment-read-only-filesystem-error/51478536#51478536
[runtime privilege and linux capabilities in docker containers]: https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
[why separate your kubernetes workload with nodepool segregation and affinity options]: https://medium.com/contino-engineering/why-separate-your-kubernetes-workload-with-nodepool-segregation-and-affinity-rules-cb5225953788

[kubectx+kubens]: https://github.com/ahmetb/kubectx
[kube-ps1]: https://github.com/jonmosco/kube-ps1
[kubie]: https://github.com/sbstp/kubie
[pulumi]: https://www.pulumi.com
