# OpenCost

Monitoring application providing real-time cost visibility and insights.

Used as base by [KubeCost].

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

Requires:

- A [Prometheus] instance to be available.

  > [!caution]
  > OpenCost's pods **will** error out and go in CrashLoopBackoff if it cannot connect to Prometheus.<br/>
  > See the Helm chart values at `opencost.prometheus` to configure that connection.

- The above Prometheus instance to have a scrape target configured for OpenCost.<br/>
  See [OpenCost extraScrapeConfigs for Prometheus].

```sh
helm repo add 'opencost' 'https://opencost.github.io/opencost-helm-chart' && helm repo update 'opencost'
helm search repo 'opencost/opencost' --versions

helm show values --repo 'https://opencost.github.io/opencost-helm-chart' 'opencost'

helm --namespace 'opencost' upgrade --install 'opencost' 'opencost/opencost' --create-namespace
helm --namespace 'opencost' upgrade --install 'opencost' --create-namespace \
  --repo 'https://opencost.github.io/opencost-helm-chart' 'opencost' \
  --set 'opencost.prometheus.internal.namespaceName=prometheus'

helm --namespace 'opencost' uninstall 'opencost' \
&& kubectl delete namespace 'opencost'
```

</details>

<details>
  <summary>Usage</summary>

```sh
kubectl --namespace 'opencost' port-forward 'service/opencost' '9003' '9090'
curl 'http://localhost:9003/allocation/compute?window=60m'
open 'http://localhost:9090'
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
- [KubeCost]

### Sources

- [Documentation]
- [Amazon EKS Integration]
- [helm chart]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[KubeCost]: kubecost.md
[Prometheus]: ../prometheus/README.md

<!-- Files -->
<!-- Upstream -->
[Amazon EKS Integration]: https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=installations-amazon-eks-integration
[codebase]: https://github.com/opencost/opencost
[documentation]: https://opencost.io/docs/
[helm chart]: https://github.com/opencost/opencost-helm-chart/
[website]: https://opencost.io/
[OpenCost extraScrapeConfigs for Prometheus]: https://raw.githubusercontent.com/opencost/opencost/develop/kubernetes/prometheus/extraScrapeConfigs.yaml

<!-- Others -->
