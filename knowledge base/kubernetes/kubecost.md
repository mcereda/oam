# Kubecost

Monitoring application providing real-time cost visibility and insights.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
helm repo add 'kubecost' 'https://kubecost.github.io/cost-analyzer/' && helm repo update 'kubecost'

helm show values --repo 'https://kubecost.github.io/cost-analyzer/' 'cost-analyzer'

helm --namespace 'kubecost' upgrade --install 'kubecost' 'kubecost/cost-analyzer' --create-namespace
helm --namespace 'kubecost' upgrade --install 'kubecost' --create-namespace \
  --repo 'https://kubecost.github.io/cost-analyzer/' 'cost-analyzer' \
  --set 'persistentVolume.enabled=false'

# EKS-specific
VERSION='' \
helm --namespace 'kubecost' upgrade --install 'kubecost' --create-namespace \
  'oci://public.ecr.aws/kubecost/cost-analyzer' --version "$VERSION" \
  --values "https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/$VERSION/cost-analyzer/values-eks-cost-monitoring.yaml"

helm --namespace 'kubecost' uninstall 'kubecost' \
&& kubectl delete namespace 'kubecost'
```

</details>

<details>
  <summary>Usage</summary>

```sh
kubectl --namespace 'kubecost' port-forward 'svc/kubecost-cost-analyzer' '9090' \
&& open 'http://localhost:9090'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]
- [Amazon EKS Integration]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Amazon EKS Integration]: https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=installations-amazon-eks-integration
[codebase]: https://github.com/kubecost
[documentation]: https://github.com/kubecost/docs
[website]: https://www.kubecost.com/

<!-- Others -->
