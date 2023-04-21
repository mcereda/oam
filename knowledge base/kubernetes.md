# Kubernetes primer

Open source container orchestration engine for containerized applications.<br />
Hosted by the [Cloud Native Computing Foundation][cncf].

1. [Composition](#composition)
   1. [The control plane](#the-control-plane)
      1. [kube-apiserver](#kube-apiserver)
      1. [etcd](#etcd)
      1. [kube-scheduler](#kube-scheduler)
      1. [kube-controller-manager](#kube-controller-manager)
      1. [cloud-controller-manager](#cloud-controller-manager)
   1. [The worker Nodes](#the-worker-nodes)
      1. [kubelet](#kubelet)
      1. [kube-proxy](#kube-proxy)
      1. [Container runtime](#container-runtime)
      1. [Addons](#addons)
1. [The API](#the-api)
1. [Managed Kubernetes Services](#managed-kubernetes-services)
1. [Security](#security)
   1. [Highly privileged containers](#highly-privileged-containers)
      1. [Capabilities](#capabilities)
      1. [Privileged container vs privilege escalation](#privileged-container-vs-privilege-escalation)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Composition

When you deploy Kubernetes, you get a _cluster_.

A K8S cluster consists of:

- one or more sets of worker machines (_Nodes_), which execute containers; every cluster must have at least one worker node;
- a _control plane_, which manages the worker Nodes and the workloads in the cluster.

The components of an application workload are called _Pods_. Pods are hosted by Nodes, are composed of containers, and are also the smallest execution unit in the cluster.

In production environments:

- the control plane usually runs across multiple Nodes;
- a cluster usually runs multiple Nodes, to provide fault-tolerance and high availability.

### The control plane

The control plane's components make global decisions about the cluster (like scheduling) and detect and respond to cluster events (like starting up a new Pod when a deployment has less replicas then it requests).

Control plane components can be run on any machine in the cluster. For simplicity, set up scripts typically start all control plane components on the same machine, and avoid running user containers on it.

#### kube-apiserver

The API server exposes the Kubernetes API, and is the front end for, and the core of, the Kubernetes control plane.

The main implementation of a Kubernetes API server is _kube-apiserver_, which is designed to scale horizontally (scales by deploying more instances) and balance traffic between its instances.

#### etcd

Consistent and highly-available key value store used as Kubernetes' backing store for all cluster data.

#### kube-scheduler

Detects newly created Pods with no assigned Node and selects one for them to run on.

Scheduling decisions take into account individual and collective resource requirements, hardware/software/policy constraints, affinity and anti-affinity specifications, data locality, inter-workload interference, and deadlines.

#### kube-controller-manager

Runs controller processes.<br />
Each controller is a separate process logically speaking, but to reduce complexity they are all compiled into a single binary and run in a single process.

Examples of these controllers are the following:

- Node controller: notices and responds when Nodes go down;
- Job controller: checks _Job_ objects (one-off tasks) and creates Pods to run them to completion;
- EndpointSlice controller: populates _EndpointSlice_ objects, which provide a link between Services and Pods;
- ServiceAccount controller: create default ServiceAccounts for new namespaces.

#### cloud-controller-manager

Embeds cloud-specific control logic, linking your cluster into your cloud provider's API and separating the components that interact with that cloud platform from the components that only interact with your cluster.

They only run controllers that are specific to your cloud provider. If you are running Kubernetes on your own premises, or in a learning environment inside your own PC, the cluster will have no cloud controller managers.

As with the kube-controller-manager, it combines several logically independent control loops into a single binary that you run as a single process. It can scale horizontally (run more than one copy) to improve performance or to help tolerate failures.

The following controllers can have cloud provider dependencies:

- Node controller: checks the cloud provider to determine if a node has been deleted in the cloud after it stops responding;
- Route controller: sets up routes in the underlying cloud infrastructure;
- Service controller: creates, updates and deletes cloud provider load balancers.

### The worker Nodes

Each Node runs components which provide a runtime environment for the cluster, and sync with the control plane to maintain workloads running as requested.

#### kubelet

Runs as an agent on each node in the cluster, making sure that containers are run in a Pod.

It takes a set of _PodSpecs_ and ensures that the containers described in them are running and healthy. It only manages containers created by Kubernetes.

#### kube-proxy

Network proxy that runs on each node and implements part of the Kubernetes Service concept.

It maintains all the network rules on nodes which allow network communication to the Pods from network sessions inside or outside of your cluster.

It uses the operating system's packet filtering layer, if there is one and it's available; if not, it forwards the traffic itself.

#### Container runtime

The software that is responsible for running containers.

Kubernetes supports container runtimes like `containerd`, `CRI-O`, and any other implementation of the Kubernetes CRI (Container Runtime Interface).

#### Addons

Addons use Kubernetes resources (_DaemonSet_, _Deployment_, etc) to implement cluster features, and as such namespaced resources for addons belong within the `kube-system` namespace.

## The API

The API server exposes an HTTP API that lets end users, different parts of your cluster, and external components communicate with one another. This lets you query and manipulate the state of API objects in Kubernetes and can be accessed through command-line tools or directly using REST calls. The serialized state of the objects is stored by writing them into `etcd`.

Consider using one of the client libraries if you are writing an application using the Kubernetes API. The complete API details are documented using OpenAPI.

Kubernetes supports multiple API versions, each at a different API path (like `/api/v1` or `/apis/rbac.authorization.k8s.io/v1alpha1`); the server handles the conversion between API versions transparently. Versioning is done at the API level rather than at the resource or field level; this ensures that the API presents a clear and consistent view of system resources and behavior, and enables controlling access to end-of-life and/or experimental APIs. All the different versions are representations of the same persisted data.

To make it easier to evolve and to extend them, Kubernetes implements API groups that can be enabled or disabled. API resources are distinguished by their **API group**, **resource type**, **namespace** (for namespaced resources), and **name**.<br />
New API resources and new resource fields can be added often and frequently. Elimination of resources or fields requires following the [API deprecation policy].

The Kubernetes API can be extended:

- using _Custom resources_ to declaratively define how the API server should provide your chosen resource API, or
- extending the Kubernetes API by implementing an aggregation layer.

## Managed Kubernetes Services

Cloud providers offer managed versions.

## Security

### Highly privileged containers

Some workloads (e.g. [ElasticSearch]) might require to change one or more system settings for performance, stability, or other issues.<br/>
This is usually achieved executing the change from a Container with high privileges, which has access to the Node's resources and breaks the isolation Containers are usually famous for. If compromised, an attacker can use this highly privileged container to gain access to the underlying Node.

To mitigate this, [Kubernetes introduced the design of a Security Context][security context design proposal].<br/>
From this document:

> A security context is a set of constraints that are applied to a Container in order to achieve the following goals (from the [Security design][Security Design Proposal]):
>
> - ensure a **clear isolation** between the Container and the underlying host it runs on;
> - **limit** the ability of the Container to negatively impact the infrastructure or other Containers.
>
> [The main idea is that] **Containers should only be granted the access they need to perform their work**. The Security Context takes advantage of containerization features such as the ability to [add or remove capabilities][Runtime privilege and Linux capabilities in Docker containers] to give a process some privileges, but not all the privileges of the `root` user.

#### Capabilities

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

#### Privileged container vs privilege escalation

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

## Further readings

- Kubernetes' [security context design proposal]
- Kubernetes' [No New Privileges Design Proposal]
- [Linux kernel documentation about `no_new_privs`][no_new_privs linux kernel documentation]
- [Linux capabilities]
- [Runtime privilege and Linux capabilities in Docker containers]
- [Container capabilities in Kubernetes]
- [Configure a Security Context for a Pod or a Container], specifically the [Set capabilities for a Container] section
- [Kubernetes SecurityContext Capabilities Explained]
- [Best practices for pod security in Azure Kubernetes Service (AKS)]
- [`kubectl`][kubectl]

## Sources

All the references in the [further readings] section, plus the following:

- Kubernetes' [concepts]

<!-- project's documentation -->
[api deprecation policy]: https://kubernetes.io/docs/reference/using-api/deprecation-policy/
[concepts]: https://kubernetes.io/docs/concepts/
[configure a security context for a pod or a container]: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
[no new privileges design proposal]: https://github.com/kubernetes/design-proposals-archive/blob/main/auth/no-new-privs.md
[security context design proposal]: https://github.com/kubernetes/design-proposals-archive/blob/main/auth/security_context.md
[security design proposal]: https://github.com/kubernetes/design-proposals-archive/blob/main/auth/security.md
[set capabilities for a container]: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container

<!-- internal references -->
[kubectl]: kubectl.md

<!-- external references -->
[best practices for pod security in azure kubernetes service (aks)]: https://learn.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security
[cncf]: https://www.cncf.io/
[container capabilities in kubernetes]: https://unofficial-kubernetes.readthedocs.io/en/latest/concepts/policy/container-capabilities/
[elasticsearch]: https://github.com/elastic/helm-charts/issues/689
[kubernetes securitycontext capabilities explained]: https://www.golinuxcloud.com/kubernetes-securitycontext-capabilities/
[linux capabilities]: https://man7.org/linux/man-pages/man7/capabilities.7.html
[no_new_privs linux kernel documentation]: https://www.kernel.org/doc/Documentation/prctl/no_new_privs.txt
[runtime privilege and linux capabilities in docker containers]: https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
