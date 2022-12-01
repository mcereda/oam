# Kubernetes primer

Open source container orchestration engine for containerized applications.<br />
Hosted by the [Cloud Native Computing Foundation][cncf].

1. [Composition](#composition)
   1. [The control plane](#the-control-plane)
      1. [kube-apiserver](#kube-apiserver)
      2. [etcd](#etcd)
      3. [kube-scheduler](#kube-scheduler)
      4. [kube-controller-manager](#kube-controller-manager)
      5. [cloud-controller-manager](#cloud-controller-manager)
   2. [The worker Nodes](#the-worker-nodes)
      1. [kubelet](#kubelet)
      2. [kube-proxy](#kube-proxy)
      3. [Container runtime](#container-runtime)
   3. [Addons](#addons)
2. [The API](#the-api)
3. [Managed Kubernetes Services](#managed-kubernetes-services)
4. [Sources](#sources)

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

### Addons

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

## Sources

- [Concepts]

<!-- project's documentation -->
[api deprecation policy]: https://kubernetes.io/docs/reference/using-api/deprecation-policy/
[concepts]: https://kubernetes.io/docs/concepts/

<!-- internal references -->

<!-- external references -->
[cncf]: https://www.cncf.io/
