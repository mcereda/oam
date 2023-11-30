# Grafana on Kubernetes using Helm

## Table of contents <!-- omit in toc -->

1. [Usage](#usage)
1. [Gotchas](#gotchas)
1. [Further readings](#further-readings)

## Usage

Installation:

1. add the repository:

   ```sh
   helm repo add grafana https://grafana.github.io/helm-charts
   helm repo update
   ```

1. install the release:

   ```sh
   helm upgrade --install --namespace monitoring --create-namespace grafana grafana/grafana
   ```

Get the admin user's password:

```sh
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

The Grafana server can be accessed via port 80 on `grafana.monitoring.svc.cluster.local` from within the cluster.<br/>
To get the external URL:

```sh
export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward "${POD_NAME}" 3000
```

Clean up:

```sh
helm delete --namespace monitoring grafana
kubectl delete namespace --ignore-not-found monitoring
```

Access a Prometheus instance in the same namespace using `http://prometheus-server`

Get the default values from the updated chart

```sh
helm inspect values grafana/grafana > "$(git rev-parse --show-toplevel)/kubernetes/helm/grafana/values.yaml"
```

## Gotchas

Useful dashboards:

- `3662`: prometheus 2.0 overview
- `6417`: kubernetes cluster (prometheus)
- `9632`: nextcloud

## Further readings

- Official [helm chart]
- [Set up prometheus and ingress on kubernetes]
- [How to integrate Prometheus and Grafana on Kubernetes using Helm]

<!--
  References
  -->

<!-- Upstream -->
[helm chart]: https://github.com/grafana/helm-charts/tree/main/charts/grafana

<!-- Others -->
[how to integrate prometheus and grafana on kubernetes using helm]: https://semaphoreci.com/blog/prometheus-grafana-kubernetes-helm
[set up prometheus and ingress on kubernetes]: https://blog.gojekengineering.com/diy-how-to-set-up-prometheus-and-ingress-on-kubernetes-d395248e2ba
