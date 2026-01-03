# Kube Resource Orchestrator

Allows defining custom Kubernetes APIs using simple and straightforward configuration.

1. [TL;DR](#tldr)
1. [Create the RDG](#create-the-rdg)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Configuring new custom APIs creates a group of Kubernetes objects and the logical operations between them.<br/>
`kro` calculates the order in which objects should be created based on Common Expression Language expressions.

CLE allows passing values from one object to another, and incorporate conditionals into the custom API definitions.<br/>
One can define default values for fields in the API specification, allowing end users to invoke custom APIs to create
grouped resources with minimal configuration.

Installing `kro` in a cluster installs the `ResourceGraphDefinition` Custom Resource Definition.

Custom APIs are created by defining Custom Resources for the `ResourceGraphDefinition` CRD.<br/>
Those CRs encapsulate the necessary resources, any additional logic, abstractions, and best practices.<br/>
When the CR is applied to the cluster, it creates a new API of the kind it describes. Users can then create an instance
of the CR, which will make the custom API handle the deployment and configuration of the required resources.

When creating an RGD, `kro`:

1. Treats resources as a Directed Acyclic Graph to understand their dependencies.
1. Validates resource definitions and detects the correct deployment order.
1. Creates a new API in the cluster from the CR.
1. Configures itself to watch and serve instances of this API, continuously reconciling the resources defined by the
   RDG.

<details>
  <summary>Setup</summary>

```sh
# Install.
helm --namespace 'kro-system' --create-namespace upgrade --install 'kro' 'oci://registry.k8s.io/kro/charts/kro'
helm -n 'kro-system' --create-namespace install 'kro' 'oci://registry.k8s.io/kro/charts/kro' --version '0.7.1'

# Uninstall.
helm -n 'kro-system' uninstall 'kro'
```

</details>

## Create the RDG

1. Create its manifest file.
1. Apply the RGD to the Kubernetes cluster:

   ```sh
   kubectl apply -f 'resourceGraphDefinition.yaml'
   ```

1. Check the status of the RGD:

   ```sh
   kubectl get rgd 'myApplication' -o 'wide'
   ```

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/awslabs/kro
[documentation]: https://kro.run/docs/
[website]: https://kro.run/

<!-- Others -->
